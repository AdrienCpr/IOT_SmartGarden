import ble_sensor
import bluetooth
from time import sleep_ms
from pyb import ADC, Pin
import dht

# --- CONFIGURATION MATÉRIELLE ---
# Ventilateur sur D6 (PA8 sur Nucleo F401RE)
motor = Pin('D6', Pin.OUT, value=0) 
soil_sensor = ADC(Pin('A0'))    
light_sensor = ADC(Pin('A3'))   
dht_sensor = dht.DHT22(Pin('D2'))

# État global du ventilateur (mis à jour par l'app ou la logique auto)
fan_state = False

def update_fan(new_state):
    global fan_state
    fan_state = new_state
    if fan_state:
        motor.on()
    else:
        motor.off()

# --- INITIALISATION BLE ---
ble = bluetooth.BLE()
# On lie l'événement 'WRITE' du Bluetooth à notre fonction update_fan
ble_device = ble_sensor.BLESensor(ble, name='SmartGarden', on_switch_callback=update_fan)

print("Système SmartGarden démarré...")

while True:
    try:
        # 1. Lectures des capteurs
        dht_sensor.measure()
        t = dht_sensor.temperature()
        h = dht_sensor.humidity()
        s_val = soil_sensor.read()
        l_val = light_sensor.read()
        
        # 2. Logique Automatique (Sécurité)
        # Si la température dépasse 28°C, on force l'allumage
        if t > 28 and not fan_state:
            print("Alerte Température ! Activation auto.")
            update_fan(True)
        
        # 3. Envoi des données vers l'application Flutter
        # Le sol est considéré humide si la valeur ADC > 500
        is_soil_wet = s_val > 500
        ble_device.set_measurements(t, h, l_val, is_soil_wet)
        
        # 4. Debug Console
        print("T:{:.1f}°C H:{:.1f}% Lux:{} Sol:{}".format(t, h, l_val, s_val))

    except Exception as e:
        print("Erreur boucle principale:", e)
    
    sleep_ms(2000)