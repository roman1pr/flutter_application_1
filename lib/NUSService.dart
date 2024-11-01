import 'dart:convert';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class NUSService {
  final FlutterBluePlus flutterBlue = FlutterBluePlus();
  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? txCharacteristic;
  BluetoothCharacteristic? rxCharacteristic;

  static const String nusServiceUUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String nusTXCharacteristicUUID = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String nusRXCharacteristicUUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E";

    // Добавляем StreamController для передачи данных
  final StreamController<String> _dataController = StreamController<String>();

  // Поток для передачи данных
  Stream<String> get dataStream => _dataController.stream;

  Future<List<BluetoothService>> getListOfServices(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;

    // Получаем доступные службы и находим NUS-службу и характеристики
    List<BluetoothService> services = await device.discoverServices();
    return services; // Возвращаем список всех служб устройства
  }

  Future<List<BluetoothService>> connectToNUSDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;

    // Получаем доступные службы и находим NUS-службу и характеристики
    List<BluetoothService> services = await device.discoverServices();

    print("Discovered!");

    for (BluetoothService service in services) {
      print("serviceTEST: ${service.uuid.toString()}");
      if (service.uuid.toString().toUpperCase() == nusServiceUUID) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          print("CHaracter: ${characteristic.uuid}");
          if (characteristic.uuid.toString().toUpperCase() == nusTXCharacteristicUUID) {
            txCharacteristic = characteristic;
          }
          if (characteristic.uuid.toString().toUpperCase() == nusRXCharacteristicUUID) {
            rxCharacteristic = characteristic;
            // await rxCharacteristic!.setNotifyValue(true);
            // rxCharacteristic!.value.listen((data) {
            //   print("Received data: ${utf8.decode(data)}");
            //    final decodedData = utf8.decode(data);
            //   _dataController.add("decodedData");
            // });
          }
        }
      }
    }
    print("END connectToNUSDevice");
    sendData("Hello NUS Device!");
    print("END 2");
    return services; // Возвращаем список всех служб устройства
  }

  Future<void> sendData(String message) async {
    print("Send DAta");
    if (txCharacteristic == null) {
      print("TX Characteristic not found");
      return;
    }
    // Отправляем данные в виде байтов
    await txCharacteristic!.write(utf8.encode(message), withoutResponse: true);
    print("Sent data: $message");
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      await connectedDevice!.disconnect();
      connectedDevice = null;
      txCharacteristic = null;
      rxCharacteristic = null;
      _dataController.close();
      print("Disconnected from device");
    }
  }
}
