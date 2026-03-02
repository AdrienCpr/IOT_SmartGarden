import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

void main() => runApp(const MyApp());

// UUIDs Blue-ST (Identiques à ton script MicroPython)
const String BLUEST_SERVICE_UUID = "00000000-0001-11e1-ac36-0002a5d5c51b";
const String TEMPERATURE_UUID    = "00040000-0001-11e1-ac36-0002a5d5c51b";
const String HUMIDITY_UUID       = "00080000-0001-11e1-ac36-0002a5d5c51b";
const String LIGHT_UUID          = "00010000-0001-11e1-ac36-0002a5d5c51b";
const String SOIL_UUID           = "01000000-0001-11e1-ac36-0002a5d5c51b";
const String SWITCH_UUID         = "20000000-0001-11e1-ac36-0002a5d5c51b";

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Garden',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const ScannerPage(),
    );
  }
}

// === PAGE SCANNER ===
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initBle();
  }

  Future<void> _initBle() async {
    if (await FlutterBluePlus.isSupported == false) return;
    if (Platform.isAndroid) await FlutterBluePlus.turnOn();

    FlutterBluePlus.scanResults.listen((results) {
      // On ne garde que les appareils qui ont un nom (ex: SmartGarden)
      final filteredResults = results.where((r) {
        final name = r.device.platformName.toLowerCase();
        return name.contains('smartgarden'); 
      }).toList();      
      if (mounted) setState(() => _scanResults = filteredResults);
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      if (mounted) setState(() => _isScanning = scanning);
    });
  }

  void _startScan() async {
    setState(() => _scanResults = []);
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 5),
      androidUsesFineLocation: true, // Crucial pour la détection sur Android
    );
  }

  void _connectToDevice(BluetoothDevice device) async {
    try { await FlutterBluePlus.stopScan(); } catch (_) {}
    if (!mounted) return;
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => DevicePage(device: device))
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recherche de la Serre'), centerTitle: true),
      body: ListView.builder(
        itemCount: _scanResults.length,
        itemBuilder: (context, index) {
          final result = _scanResults[index];
          return ListTile(
            leading: const Icon(Icons.bluetooth, color: Colors.green),
            title: Text(result.device.platformName),
            subtitle: Text(result.device.remoteId.toString()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _connectToDevice(result.device),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _startScan,
        child: _isScanning 
            ? const CircularProgressIndicator(color: Colors.white) 
            : const Icon(Icons.bluetooth_searching),
      ),
    );
  }
}

// === PAGE SMART GARDEN (INTERFACE FINALE) ===
class DevicePage extends StatefulWidget {
  final BluetoothDevice device;
  const DevicePage({super.key, required this.device});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  bool _isConnecting = true;
  bool _isConnected = false;
  
  BluetoothCharacteristic? _switchChar;
  double? _temp, _hum;
  int? _light;
  bool _soilWet = false;
  bool _fanOn = false;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      await widget.device.connect(timeout: const Duration(seconds: 10));
      if (mounted) setState(() { _isConnecting = false; _isConnected = true; });
      await _setupServices();
    } catch (e) {
      if (mounted) setState(() { _isConnecting = false; _isConnected = false; });
    }
  }

  Future<void> _setupServices() async {
    final services = await widget.device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == BLUEST_SERVICE_UUID) {
        for (var c in service.characteristics) {
          final uuid = c.uuid.toString().toLowerCase();

          if (uuid == TEMPERATURE_UUID) {
            await c.setNotifyValue(true);
            c.onValueReceived.listen((v) {
              if (v.length >= 4 && mounted) {
                final val = ByteData.sublistView(Uint8List.fromList(v)).getFloat32(0, Endian.little);
                setState(() => _temp = val);
              }
            });
          } else if (uuid == HUMIDITY_UUID) {
            await c.setNotifyValue(true);
            c.onValueReceived.listen((v) {
              if (v.length >= 4 && mounted) {
                final val = ByteData.sublistView(Uint8List.fromList(v)).getFloat32(0, Endian.little);
                setState(() => _hum = val);
              }
            });
          } else if (uuid == LIGHT_UUID) {
            await c.setNotifyValue(true);
            c.onValueReceived.listen((v) {
              if (v.length >= 2 && mounted) {
                final val = ByteData.sublistView(Uint8List.fromList(v)).getUint16(0, Endian.little);
                setState(() => _light = val);
              }
            });
          } else if (uuid == SOIL_UUID) {
            await c.setNotifyValue(true);
            c.onValueReceived.listen((v) {
              if (v.isNotEmpty && mounted) {
                setState(() => _soilWet = v[0] == 1);
              }
            });
          } else if (uuid == SWITCH_UUID) {
            _switchChar = c;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    widget.device.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.device.platformName)),
      body: _isConnecting 
          ? const Center(child: CircularProgressIndicator()) 
          : !_isConnected 
              ? const Center(child: Text('Échec de la connexion'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSoilStatus(),
                      const SizedBox(height: 20),
                      _buildDataTile(Icons.thermostat, "Température", "${_temp?.toStringAsFixed(1) ?? '--'}°C", Colors.orange),
                      _buildDataTile(Icons.water_drop, "Humidité Air", "${_hum?.toStringAsFixed(1) ?? '--'}%", Colors.blue),
                      _buildDataTile(Icons.wb_sunny, "Luminosité", "${_light ?? '--'} lx", Colors.amber),
                      const Spacer(),
                      _buildFanControl(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSoilStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _soilWet ? Colors.blue[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _soilWet ? Colors.blue : Colors.red, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_soilWet ? Icons.check_circle : Icons.warning, color: _soilWet ? Colors.blue : Colors.red),
          const SizedBox(width: 12),
          Text(_soilWet ? "SOL BIEN HUMIDE" : "SOL SEC : ARROSER !", 
               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildDataTile(IconData icon, String label, String value, Color color) {
    return Card(
      elevation: 0,
      color: Colors.grey[50],
      shape: RoundedRectangleBorder(side: BorderSide(color: Colors.grey[200]!), borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(label, style: const TextStyle(color: Colors.grey)),
        trailing: Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFanControl() {
    return SizedBox(
      width: double.infinity,
      height: 75,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: _fanOn ? Colors.blue : Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: () async {
          if (_switchChar != null) {
            _fanOn = !_fanOn;
            await _switchChar!.write([_fanOn ? 1 : 0]);
            setState(() {});
          }
        },
        icon: Icon(_fanOn ? Icons.wind_power : Icons.wind_power_outlined, size: 30),
        label: Text(_fanOn ? 'ARRÊTER LE VENTILATEUR' : 'ALLUMER LE VENTILATEUR',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}