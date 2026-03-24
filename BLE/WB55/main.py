import ble_sensor
import bluetooth
import time
from pyb import ADC, Pin, UART
import dht

# --- 1. CONFIGURATION MATÉRIELLE ---
soil_sensor  = ADC(Pin('A0'))
light_sensor = ADC(Pin('A3'))
dht_sensor   = dht.DHT22(Pin('D2'))
motor        = Pin('D6', Pin.OUT, value=0)
uart         = UART(2, 115200)

# --- 2. VARIABLES GLOBALES ---
fan_state = False

def update_fan(new_state):
    global fan_state
    fan_state = new_state
    motor.on() if fan_state else motor.off()
    print(">>> Ventilateur :", "ALLUMÉ" if fan_state else "ÉTEINT")

# --- 3. BLE ---
ble = bluetooth.BLE()
ble_device = ble_sensor.BLESensor(ble, name='SmartGarden', on_switch_callback=update_fan)
print("--- Système SmartGarden Démarré ---")
time.sleep(1)

# --- 4. BOUCLE PRINCIPALE ---
while True:
    try:
        try:
            dht_sensor.measure()
            t = dht_sensor.temperature()
            h = dht_sensor.humidity()
        except Exception:
            print("Erreur DHT22 - valeurs par défaut")
            t, h = 22.0, 45.0

        s_val = soil_sensor.read()
        l_val = light_sensor.read()

        if t > 28.0 and not fan_state:
            update_fan(True)

        is_soil_wet = 1 if s_val > 500 else 0
        is_fan_on   = 1 if fan_state else 0

        payload = "#{:.1f},{:.1f},{},{},{}!".format(t, h, l_val, is_soil_wet, is_fan_on)
        uart.write(payload)

        ble_device.set_measurements(t, h, l_val, bool(is_soil_wet))
        print("TX:", payload)
       
        if uart.any():
            data = uart.read().decode('utf-8').strip() # On lit tout d'un coup
            print("Données brutes reçues :", data) # <--- AJOUTE CETTE LIGNE
            
            if "FAN_ON" in data: # Utilise "in" au lieu de "==" c'est plus robuste
                update_fan(True)
            elif "FAN_OFF" in data:
                update_fan(False)


    except Exception as e:
        print("Erreur :", e)

    time.sleep(2)