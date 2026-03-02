import bluetooth
from ble_advertising import advertising_payload
from struct import pack
from micropython import const
import pyb
from binascii import hexlify

# Constantes IRQ Bluetooth
_IRQ_CENTRAL_CONNECT    = const(1)
_IRQ_CENTRAL_DISCONNECT = const(2) 
_IRQ_GATTS_WRITE        = const(3)

# UUIDs Blue-ST (Identiques à ton app Flutter)
_ST_APP_UUID = bluetooth.UUID('00000000-0001-11E1-AC36-0002A5D5C51B')

_TEMP_UUID    = (bluetooth.UUID('00040000-0001-11E1-AC36-0002A5D5C51B'), bluetooth.FLAG_NOTIFY)
_HUM_AIR_UUID = (bluetooth.UUID('00080000-0001-11E1-AC36-0002A5D5C51B'), bluetooth.FLAG_NOTIFY)
_LIGHT_UUID   = (bluetooth.UUID('00010000-0001-11E1-AC36-0002A5D5C51B'), bluetooth.FLAG_NOTIFY)
_SOIL_UUID    = (bluetooth.UUID('01000000-0001-11E1-AC36-0002A5D5C51B'), bluetooth.FLAG_NOTIFY)
_SWITCH_UUID  = (bluetooth.UUID('20000000-0001-11E1-AC36-0002A5D5C51B'), bluetooth.FLAG_WRITE | bluetooth.FLAG_NOTIFY)

_ST_APP_SERVICE = (_ST_APP_UUID, (_TEMP_UUID, _HUM_AIR_UUID, _LIGHT_UUID, _SOIL_UUID, _SWITCH_UUID))

# Identifiant Manufacturer ST
_MANUFACTURER = pack('>BBI6B', 0x01, 0x80, 0x200D0000, 0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC)

led_blue = pyb.LED(1) # Connexion
led_red = pyb.LED(3)  # État Ventilateur

class BLESensor:
    def __init__(self, ble, name='SmartGarden', on_switch_callback=None):
        self._ble = ble
        self._ble.active(True)
        self._ble.irq(self._irq)
        # Enregistrement des services
        ((self._temp_h, self._hum_h, self._light_h, self._soil_h, self._switch_h),) = self._ble.gatts_register_services((_ST_APP_SERVICE,))
        self._connections = set()
        self._payload = advertising_payload(name=name, manufacturer=_MANUFACTURER)
        self._on_switch_callback = on_switch_callback
        self._advertise()
        print("BLE prêt : %s" % hexlify(self._ble.config('mac')[1]).decode("ascii"))

    def _irq(self, event, data):
        if event == _IRQ_CENTRAL_CONNECT:
            self._connections.add(data[0])
            led_blue.on()
        elif event == _IRQ_CENTRAL_DISCONNECT:
            self._connections.remove(data[0])
            led_blue.off()
            self._advertise()
        elif event == _IRQ_GATTS_WRITE:
            conn_handle, value_handle = data
            if value_handle == self._switch_h:
                msg = self._ble.gatts_read(self._switch_h)
                state = msg[0] == 1
                # Retour visuel sur la carte
                if state: led_red.on()
                else: led_red.off()
                # Exécution de la commande moteur
                if self._on_switch_callback:
                    self._on_switch_callback(state)

    def set_measurements(self, temp, hum, light, soil_wet):
        # Écriture des valeurs dans les caractéristiques
        self._ble.gatts_write(self._temp_h, pack('<f', temp))
        self._ble.gatts_write(self._hum_h, pack('<f', hum))
        self._ble.gatts_write(self._light_h, pack('<H', int(light)))
        self._ble.gatts_write(self._soil_h, pack('<B', 1 if soil_wet else 0))
        
        # Notification des smartphones connectés
        for conn in self._connections:
            self._ble.gatts_notify(conn, self._temp_h)
            self._ble.gatts_notify(conn, self._hum_h)
            self._ble.gatts_notify(conn, self._light_h)
            self._ble.gatts_notify(conn, self._soil_h)

    def _advertise(self, interval_us=500000):
        self._ble.gap_advertise(interval_us, adv_data=self._payload, connectable=True)