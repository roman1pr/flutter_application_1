// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'dart:convert';

// class NUSService2 {
//   final FlutterBluePlus flutterBlue = FlutterBluePlus;
//   BluetoothDevice? connectedDevice;
//   BluetoothCharacteristic? txCharacteristic;
//   BluetoothCharacteristic? rxCharacteristic;

//   static const String nusServiceUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
//   static const String nusTXCharacteristicUUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
//   static const String nusRXCharacteristicUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";

//   // Метод для сканирования и подключения к устройству с сервисом NUS
//   Future<void> scanAndConnect() async {
//     flutterBlue.startScan(timeout: Duration(seconds: 5));
    
//     flutterBlue.scanResults.listen((results) async {
//       for (ScanResult result in results) {
//         if (result.advertisementData.serviceUuids.contains(nusServiceUUID)) {
//           print("Найдено устройство с NUS: ${result.device.name} [${result.device.id}]");
//           await connectToNUSDevice(result.device);
//           flutterBlue.stopScan();
//           break;
//         }
//       }
//     });
//   }

//   // Метод для подключения к устройству и поиска характеристик NUS
//   Future<void> connectToNUSDevice(BluetoothDevice device) async {
//     await device.connect();
//     connectedDevice = device;

//     List<BluetoothService> services = await device.discoverServices();
//     for (BluetoothService service in services) {
//       if (service.uuid.toString().toUpperCase() == nusServiceUUID) {
//         for (BluetoothCharacteristic characteristic in service.characteristics) {
//           if (characteristic.uuid.toString().toUpperCase() == nusTXCharacteristicUUID) {
//             txCharacteristic = characteristic;
//           }
//           if (characteristic.uuid.toString().toUpperCase() == nusRXCharacteristicUUID) {
//             rxCharacteristic = characteristic;
//             await rxCharacteristic!.setNotifyValue(true);
//             rxCharacteristic!.value.listen((data) {
//               print("Received data: ${utf8.decode(data)}");
//             });
//           }
//         }
//       }
//     }
//     print("Подключение к устройству ${device.name} завершено.");
//   }

//   // Метод для отправки данных
//   Future<void> sendData(String message) async {
//     if (txCharacteristic == null) {
//       print("TX Characteristic not found");
//       return;
//     }
//     await txCharacteristic!.write(utf8.encode(message), withoutResponse: true);
//     print("Sent data: $message");
//   }

//   // Метод для отключения от устройства
//   Future<void> disconnect() async {
//     if (connectedDevice != null) {
//       await connectedDevice!.disconnect();
//       connectedDevice = null;
//       txCharacteristic = null;
//       rxCharacteristic = null;
//       print("Disconnected from device");
//     }
//   }
// }
