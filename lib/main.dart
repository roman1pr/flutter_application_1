import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'NUSService.dart';

void main() {
  runApp(BluetoothScannerApp());
}

class BluetoothScannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth NUS Scanner',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: BluetoothScannerScreen(),
    );
  }
}

class BluetoothScannerScreen extends StatefulWidget {
  @override
  _BluetoothScannerScreenState createState() => _BluetoothScannerScreenState();
}

class _BluetoothScannerScreenState extends State<BluetoothScannerScreen> {
  // FlutterBluePlus flutterBlue = FlutterBluePlus();
  List<ScanResult> scanResults = [];
  final NUSService nusService = NUSService();

  BluetoothAdapterState _adapterState = BluetoothAdapterState.unknown;
  late StreamSubscription<BluetoothAdapterState> _adapterStateStateSubscription;
  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;

  @override
  void initState() {
    super.initState();
    _adapterStateStateSubscription =
        FlutterBluePlus.adapterState.listen((state) {
      _adapterState = state;
      if (mounted) {
        setState(() {});
      }
    });

    // Подписываемся на поток данных NUS
    nusService.dataStream.listen((data) {
      showDataTip(data); // Вызываем Snackbar с полученными данными
    });
  }

  Future<void> startScan() async {
    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult r = results.last; // the most recently found device
          print(
              '${r.device.remoteId}: "${r.advertisementData.advName}" found!');
        }
      },
      onError: (e) => print(e),
    );

  // cleanup: cancel subscription when scanning stops
    FlutterBluePlus.cancelWhenScanComplete(subscription);

  // Wait for Bluetooth enabled & permission granted
  // In your real app you should use `FlutterBluePlus.adapterState.listen` to handle all states
    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

  // Start scanning w/ timeout
  // Optional: use `stopScan()` as an alternative to timeout
    await FlutterBluePlus.startScan(
        // withServices: [Guid("180D")], // match any of the specified services
        // withNames: ["Bluno"], // *or* any of the specified names
        timeout: Duration(seconds: 5));

  // wait for scanning to stop
    await FlutterBluePlus.isScanning.where((val) => val == false).first;

    print("isScanning finished");
  }

  // Метод для отображения Snackbar с данными
  void showDataTip(String data) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Received data: $data"),
        duration: Duration(seconds: 2),
      ),
    );
  } 

  Future<void> connectToDeviceAndShowServices(ScanResult result) async {
    // Подключаемся к устройству и получаем список служб

    List<BluetoothService> services =
        await nusService.getListOfServices(result.device);
    // Показываем доступные службы
    showServicesDialog(services, result.device);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth NUS Scanner'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                scanResults.clear();
              });
              startScan();
            },
          ),
        ],
      ),
      body: scanResults.isEmpty
          ? Center(child: Text('Scanning for devices...'))
          : ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                final result = scanResults[index];

                return ListTile(
                  title: Text(
                    result.device.name.isEmpty
                        ? 'Unknown Device'
                        : result.device.name,
                    style: TextStyle(
                      color: result.advertisementData.serviceUuids
                              .contains(NUSService.nusServiceUUID)
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  subtitle: Text('RSSI: ${result.rssi} dBm'),
                  trailing: Text(result.device.id.toString()),
                  onTap: () => connectToDeviceAndShowServices(
                      result), // При нажатии подключаемся к устройству по NUS
                );
              },
            ),
    );
  }

  void showServicesDialog(
      List<BluetoothService> services, BluetoothDevice device) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Available Services: ${nusService.txCharacteristic?.deviceId.id}",
          ),
          content: SingleChildScrollView(
            child: Column(
              children: services.map((service) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Service UUID: ${service.uuid}"),
                    ...service.characteristics.map((characteristic) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          "Characteristic UUID: ${characteristic.uuid}",
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 10),
                  ],
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
            ),
            TextButton(
              onPressed: () {
                nusService.connectToNUSDevice(device);
              },
              child: Text("Print"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // flutterBlue.stopScan();
    nusService.disconnect(); // Отключаемся при выходе
    super.dispose();
  }
}
