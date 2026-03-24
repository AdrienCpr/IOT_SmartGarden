# 🌿 SmartGarden - Système de Surveillance Intelligent

**SmartGarden** est une solution IoT complète permettant de surveiller et de contrôler l'environnement d'une serre en temps réel. Le projet repose sur une architecture robuste à deux cartes communiquant par liaison série (UART), intégrant une interface graphique tactile et une connectivité Bluetooth.

---

## 🚀 Fonctionnalités

- **Dashboard Tactile :** Interface développée avec **TouchGFX** sur STM32F746G (Cortex-M7).
- **Capteurs en Temps Réel :** Affichage de la température (°C), de l'humidité de l'air (%), de la luminosité (Lux) et de l'humidité du sol.
- **Contrôle d'Actionneur :** Gestion d'un ventilateur (Fan) en mode automatique (seuil de température) ou via un bouton tactile sur l'écran.
- **Indicateurs Dynamiques :** Jauges animées et messages d'état textuels (SEC/HUMIDE).
- **Double Connectivité :** Monitoring via l'écran LCD et transmission des données en **Bluetooth (BLE)** vers une application mobile.

---

## 🛠️ Stack Technique

### Matériel (Hardware)
- **Écran :** STM32F746G-Discovery (Master IHM).
- **Contrôleur Capteurs & BLE :** STM32WB55 + Shield (Slave & Gateway).
- **Application Mobile :** Développée avec **Flutter** (Utilisation de `flutter_blue_plus`).
- **Capteurs :** DHT22 (Air), Photorésistance (Lumière), Capteur capacitif (Sol).

### Logiciel (Software)
- **C++ (Discovery) :** Interface graphique TouchGFX.
- **C (WB55) :** Gestion de la pile BLE (Service personnalisé) et lecture ADC/GPIO.
- **Dart (App) :** Interface Flutter pour le monitoring distant.
---

## 🏗️ Architecture Logicielle (MVP)

Le projet suit le design pattern **Model-View-Presenter (MVP)** pour séparer les données de l'affichage :

1. **Model :** Réceptionne les trames UART, décode les données (`strtok`, `atof`) et lève des drapeaux (`msg_ready_flag`).
2. **Presenter :** Fait le pont entre le Model et la Vue.
3. **View :** Gère le rendu des jauges, met à jour les buffers de texte (Wildcards) et capture les événements boutons.

---

## 🔌 Schéma de Communication

### Format des Trames (UART - 115200 baud)
- **Nucleo ➔ Discovery :** `#{Temp},{Hum},{Lux},{Soil_Wet},{Fan_State}!`
    - *Exemple : `#24.5,55.0,850,1,0!`*
- **Discovery ➔ Nucleo :** `FAN_ON` ou `FAN_OFF`

### Branchements
| Signal | Discovery (F746) | Nucleo (L476) |
| :--- | :--- | :--- |
| **TX** | PC6 | RX (LPUART/UART2) |
| **RX** | PC7 | TX (LPUART/UART2) |
| **GND** | GND | GND |

---

## 📦 Installation

1. **Côté Nucleo (MicroPython) :**
    - Flasher le firmware MicroPython.
    - Copier les scripts `main.py`, `ble_sensor.py`.
    - Connecter les capteurs sur les pins A0, A3, D2, D6.

2. **Côté Discovery (TouchGFX) :**
    - Ouvrir le projet dans **STM32CubeIDE**.
    - Vérifier l'activation du **CRC** dans le `.ioc`.
    - Compiler et flasher.

---

## 🎨 Aperçu du Design

L'interface a été conçue pour une lisibilité maximale :
- **Police :** Verdana / Roboto pour une netteté optimale sur écran LCD.
- **Couleurs :** Thème "Nature" (Vert émeraude #27AE60, Blanc cassé #F4F7F6).
- **Widgets :** Jauges circulaires pour les métriques environnementales et boutons à deux états (Pressed/Released) pour le contrôle manuel.