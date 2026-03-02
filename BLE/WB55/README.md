# IoT BLE STM32 MicroPython

Implémentation d'un périphérique BLE avec le protocole Blue-ST sur STM32 NUCLEO-WB55 en MicroPython.

## Fonctionnalités

- Broadcast BLE (advertising)
- Service GATT Blue-ST
- Caractéristique Température (notify)
- Caractéristique Switch LED (write)

## Fichiers

- `main.py` : Boucle principale, envoi température toutes les 5s
- `ble_sensor.py` : Classe BLESensor, logique GATT
- `ble_advertising.py` : Construction des trames advertising
- `bme280.py` : Driver capteur BME280 (optionnel)

## Matériel

- STM32 NUCLEO-WB55
- (Optionnel) Capteur BME280 en I2C

## UUIDs Blue-ST

| Caractéristique | UUID |
|-----------------|------|
| Service | 00000000-0001-11E1-AC36-0002A5D5C51B |
| Température | 00040000-0001-11E1-AC36-0002A5D5C51B |
| Switch LED | 20000000-0001-11E1-AC36-0002A5D5C51B |