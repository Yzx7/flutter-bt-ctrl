// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MainProvider with ChangeNotifier {
  final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  bool _bluetoothState = false;
  bool _isConnecting = false;

  List<ScanResult> _devices = [];
  List<BluetoothDevice> _systemdevices = [];

  BluetoothDevice? _deviceConnected;
  StreamSubscription<List<ScanResult>>? subscriptionScan;
  BluetoothCharacteristic? targetCharacteristic;

  PermissionStatus _blPersmission = PermissionStatus.denied;
  PermissionStatus _blScanPersmission = PermissionStatus.denied;
  PermissionStatus _blConnectPersmission = PermissionStatus.denied;
  // final blueClassic =
  // FlutterBlueClassic(usesFineLocation: true);

  int times = 0;

  bool get blOkPermissionisGranted => _blPersmission.isGranted && _blScanPersmission.isGranted && _blConnectPersmission.isGranted;
  BluetoothDevice? get deviceConnected => _deviceConnected;
  List<ScanResult> get devices => _devices;
  List<BluetoothDevice> get systemdevices => _systemdevices;

  bool get btIsConecting => _isConnecting;
  bool get bluetoothState => _bluetoothState;
  bool get btIsConected => _deviceConnected?.isConnected ?? false;

  // btEnable(bool r) async {
  //   if (r) {
  //     await _bluetooth.requestEnable();
  //   } else {
  //     await _bluetooth.requestDisable();
  //   }
  // }

  MainProvider(BuildContext context) {
    FlutterBluePlus.setLogLevel(LogLevel.none, color: false);

    checkBTPermissiosn();

    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (state == BluetoothAdapterState.unauthorized) {
        _bluetoothState = false;
      } else {
        _bluetoothState = false;
      }
      if (state == BluetoothAdapterState.on) {
        _bluetoothState = true;
        // usually start scanning, connecting, etc
      } else {
        _bluetoothState = false;
        // show an error to the user, etc
      }
      notifyListeners();
    });
  }

  Future getDevices() async {
    if (subscriptionScan != null) {
      subscriptionScan?.cancel();
    }

    // FlutterBluePlus.bondedDevices
    _systemdevices = await FlutterBluePlus.bondedDevices;
    // _systemdevices = await FlutterBluePlus.systemDevices;
    print(_systemdevices);
    notifyListeners();

    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          _devices = results;
          notifyListeners();
          ScanResult r = results.last; // the most recently found device
          print('${r.device.remoteId}: "${r.advertisementData.advName}" found!');
        }
      },
      onError: (e) => print(e),
    );

    // cleanup: cancel subscription when scanning stops
    FlutterBluePlus.cancelWhenScanComplete(subscription);
    subscriptionScan = subscription;
    notifyListeners();

    // Wait for Bluetooth enabled & permission granted
    // In your real app you should use `FlutterBluePlus.adapterState.listen` to handle all states
    await FlutterBluePlus.adapterState.where((val) => val == BluetoothAdapterState.on).first;

    // Start scanning w/ timeout
    // Optional: use `stopScan()` as an alternative to timeout
    await FlutterBluePlus.startScan(
        // withServices: [Guid("180D")], // match any of the specified services
        // withNames: ["Bluno"], // *or* any of the specified names
        timeout: const Duration(seconds: 15));

    // wait for scanning to stop
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
  }

  Future checkBTPermissiosn() async {
    _blPersmission = await Permission.bluetooth.status;
    _blScanPersmission = await Permission.bluetoothScan.status;
    _blConnectPersmission = await Permission.bluetoothConnect.status;
  }

  Future reqBTPermission() async {
    if (_blPersmission.isDenied) {
      await Permission.bluetooth.onGrantedCallback(() {
        _blPersmission = PermissionStatus.granted;
        notifyListeners();
      }).request();
    }
    if (_blScanPersmission.isDenied) {
      await Permission.bluetoothScan.onGrantedCallback(() {
        _blScanPersmission = PermissionStatus.granted;
        notifyListeners();
      }).request();
    }
    if (_blConnectPersmission.isDenied) {
      await Permission.bluetoothConnect.onGrantedCallback(() {
        _blConnectPersmission = PermissionStatus.granted;
        notifyListeners();
      }).request();
    }
  }

  sendData(String data) async {
    if (targetCharacteristic == null) return;

    List<int> bytes = utf8.encode(data);
    await targetCharacteristic?.write(bytes);
  }

  discoverServices() async {
    if (_deviceConnected == null) {
      return;
    }

    List<BluetoothService> services = await _deviceConnected!.discoverServices();

    for (var service in services) {
      // do something with service
      if (service.uuid.toString() == SERVICE_UUID) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            targetCharacteristic = characteristic;
            sendData("Hi there, ESP32!!");
            // connectionText = "All Ready with ${targetDevice.name}"
            notifyListeners();
          }
        }
      }
    }
  }

  Future requestBTPermission() async {
    await Permission.location.request();
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  Future btConnectTo(BluetoothDevice devc) async {
    try {
      _isConnecting = true;
      await devc.connect();

      _deviceConnected = devc.isConnected ? devc : null;
      // _devices = [];
      discoverServices();
      _isConnecting = false;
      var subscription = _deviceConnected?.connectionState.listen((BluetoothConnectionState state) async {
        if (state == BluetoothConnectionState.disconnected) {
          // 1. typically, start a periodic timer that tries to
          //    reconnect, or just call connect() again right now
          // 2. you must always re-discover services after disconnection!
          print("${_deviceConnected?.disconnectReason} ${_deviceConnected?.disconnectReason}");
          _deviceConnected = null;
          notifyListeners();
        }
      });
      if (subscription != null) {
        _deviceConnected?.cancelWhenDisconnected(subscription, delayed: true, next: true);
      }

      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future btDeviceDisconect() async {
    if (btIsConected) {
      await _deviceConnected?.disconnect();
      _deviceConnected = null;
      notifyListeners();
    }
  }
}
