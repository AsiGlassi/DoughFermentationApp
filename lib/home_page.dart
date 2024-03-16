import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dough_fermentation/Messages.dart';

import 'dart:async';

import 'package:flutter_blue/flutter_blue.dart';

const String DOUGH_DEVICE_NAME = "Asi Dough Height";
const String DOUGH_HEIGHT_SERVICE_UUID = "3ee2ffbe-e236-41f2-9c40-d44563ddc614";
const String CHARACTERISTIC_HEIGHT_UUID = "7daf9c2b-715c-4a1c-b889-1ccd50817186";
const String CHARACTERISTIC_FERMENTATION_UUID = "8d0ca8ce-5c66-4e31-ba1a-48868601ec25";
const String CHARACTERISTIC_START_UUID = "fc70539e-2e17-4cf8-b7e2-4375fc7ded5a";
const String CHARACTERISTIC_STATUS_UUID = "a1990b88-249f-45b2-a0b2-ba0f1f90ca0a";
const String CHARACTERISTIC_DESIRED_FERMENTATION_UUID = "b1f4f8ec-efd5-4fd9-be66-09bbb9baa1da";

enum DoughServcieStatusEnum { idle, Connected, Fermenting, ReachedDesiredFerm, OverFerm, Error }
final List<Color> doughServcieStatuColors = <Color>[
  const Color.fromARGB(0xFF, 0xFF, 0xFF, 0xFF), //GRB 0xFFFFFF,
  const Color.fromARGB(0xFF, 0xAC, 0x61, 0x99), //GRB 0xAC6199
  const Color.fromARGB(0xFF, 0xFF, 0xFF, 0x88), //GRB 0xFFFF88
  const Color.fromARGB(0xFF, 0x33, 0xFF, 0x33), //GRB 0x33FF33
  const Color.fromARGB(0xFF, 0xFF, 0x75, 0x33), //GRB 0xFF7533
  const Color.fromARGB(0xFF, 0xEE, 0x33, 0x33)  //GRB 0xEE3333
];


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var cblack = Colors.black;
  bool statusChangeByUser = false;

  FlutterBlue flutterBlue = FlutterBlue.instance;
  BluetoothState btState = BluetoothState.unknown;
  late BluetoothDevice asiDoughDevice;
  bool isConnecting = true;
  BluetoothDeviceState asiDoughDeviceState = BluetoothDeviceState.disconnected;
  BluetoothCharacteristic? startStopCharactaristics = null;
  DoughServcieStatusEnum doughServcieStatus = DoughServcieStatusEnum.idle;
  int doughHeight = 0;
  double fermPrecentage = 0.0;

  //event subscription
  late StreamSubscription<List<int>> statusCharSub;
  late StreamSubscription<List<int>> heightCharSub;

  @override
  Widget build(BuildContext context) {
    final my_color_variable = Colors.red;
    return Center(
      child: Column(children: [
        // ElevatedButton(
        //   onPressed: () {
        //     debugPrint('Looking for BLE');
        //     var bleDoughDevice = ScanBleDoughDevice(flutterBlue);
        //   },
        //   child: const Text(
        //     'Connect Asi Dough BLE',
        //   ),
        // ),

        // Bluethooth
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10.0),
          margin: const EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 10.0),
          color: Colors.cyan[50],
          child: Container(
            margin: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(color: Colors.greenAccent, border: Border.all(color: Colors.blueAccent)),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.lightGreen[50], border: Border.all(color: Colors.orange, width: 2.0)),
                    padding: EdgeInsets.all(1.0),
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
                      //BT Icon
                      Icon(
                        size: 30.0,
                        btState == BluetoothState.off ? Icons.bluetooth_disabled : Icons.bluetooth_outlined,
                        color: btState == BluetoothState.off ? Colors.redAccent : Colors.blue,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          btState == BluetoothState.off ? 'BT Off' : 'BT On',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ]),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Colors.lightGreen[50], border: Border.all(color: Colors.orange, width: 2.0)),
                    padding: EdgeInsets.all(1.0),
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        //Change device conn status
                        switch (asiDoughDeviceState) {
                          case BluetoothDeviceState.disconnected:
                            debugPrint('Scanning for Devcie ...');
                            await ScanBleDoughDevice(flutterBlue);
                            break;
                          case BluetoothDeviceState.disconnecting:
                            {
                              debugPrint('Connecting back...');
                              await asiDoughDevice.connect();
                            }
                            break;
                          case BluetoothDeviceState.connected:
                          case BluetoothDeviceState.connecting:
                            {
                              debugPrint('Disconnecting device');
                              statusChangeByUser = true;
                              DisconnectingDevice();
                            }
                            break;
                        }
                      },
                      child: Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
                        //Device Connected Icon
                        Icon(
                          size: 30.0,
                          asiDoughDeviceState == BluetoothDeviceState.disconnected
                              ? Icons.bluetooth_outlined
                              : Icons.bluetooth_connected,
                          color: asiDoughDeviceState == BluetoothDeviceState.disconnected ? Colors.grey : Colors.blue,
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            asiDoughDeviceState == BluetoothDeviceState.disconnected ? 'Not Connected' : 'Connected',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ]),
          ),
        ),

        // Service
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10.0),
          margin: const EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 10.0),
          color: Colors.cyan[100],
          child: Container(
            margin: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
                color: Colors.cyan[75],
                border: Border.all(
                  color: Colors.blueAccent,
                )),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                    ),
                    onPressed: (asiDoughDeviceState != BluetoothDeviceState.connected)
                        ? null
                        : () async {
                          if ((startStopCharactaristics != null) && (asiDoughDeviceState == BluetoothDeviceState.connected)) {
                            if ((doughServcieStatus == DoughServcieStatusEnum.idle) || (doughServcieStatus == DoughServcieStatusEnum.Connected)) {
                                debugPrint('Start Fermentation Monitoring.');
                                await startStopCharactaristics?.write([0x1]);
                            } else {
                              debugPrint('Stop Fermentation Monitoring.');
                              await startStopCharactaristics?.write([0x0]);
                            }
                            }
                          },
                    child: Text(((doughServcieStatus == DoughServcieStatusEnum.idle) || (doughServcieStatus == DoughServcieStatusEnum.Connected)) ? 'Start' : 'Stop',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: asiDoughDeviceState == BluetoothDeviceState.connected ? Colors.black : Colors.grey,
                        )),
                  ),
                  //Fermentation Status -   idle, Fermenting, ReachedDesiredFerm, OverFerm, Error
                  Container(
                    decoration:
                        BoxDecoration(color: doughServcieStatuColors[doughServcieStatus.index], border: Border.all(color: Colors.lightBlue, width: 2.0)),
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
                      //BT Icon
                      Icon(
                        size: 30.0,
                        doughServcieStatus == DoughServcieStatusEnum.idle
                            ? Icons.hourglass_empty
                            :doughServcieStatus == DoughServcieStatusEnum.Connected
                            ? Icons.bluetooth_connected
                              : doughServcieStatus == DoughServcieStatusEnum.Fermenting
                                  ? Icons.hourglass_bottom
                                  : doughServcieStatus == DoughServcieStatusEnum.ReachedDesiredFerm
                                      ? Icons.hourglass_full
                                      : doughServcieStatus == DoughServcieStatusEnum.OverFerm
                                          ? Icons.upload_sharp
                                          : Icons.error_outline,
                        color: btState == DoughServcieStatusEnum.Error ? Colors.red : Colors.blue,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          doughServcieStatus == DoughServcieStatusEnum.idle
                              ? 'Idle'
                              : doughServcieStatus == DoughServcieStatusEnum.Connected
                                ? 'Connected'
                                : doughServcieStatus == DoughServcieStatusEnum.Fermenting
                                    ? 'Fermenting'
                                    : doughServcieStatus == DoughServcieStatusEnum.ReachedDesiredFerm
                                        ? 'Done'
                                        : doughServcieStatus == DoughServcieStatusEnum.OverFerm
                                            ? 'Over Fermentation'
                                            : 'Error',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10.0),
                        alignment: Alignment.bottomRight,
                        child: Text(
                          '${fermPrecentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ]),
                  ),

                  Container(
                    decoration: BoxDecoration(
                        color: Colors.lightGreen[50], border: Border.all(color: Colors.lightBlue, width: 2.0)),
                    margin: const EdgeInsets.symmetric(vertical: 5.0),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        discoverBleDoughServices();
                      },
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            //Device Height Data
                            Text('Debug Data, Height ${doughHeight}'),
                            // Text('Row Text'),
                            // Text('Row Text'),
                          ]),
                    ),
                  ),
                ]),
          ),
        ),
      ]),
    );
  }

  @override
  void initState() {
    super.initState();

    //checks bluetooth current state
    FlutterBlue.instance.state.listen((state) {
      setState(() {
        btState = state;
      });
      if (state == BluetoothState.off) {
        //Alert user to turn on bluetooth.
      } else if (state == BluetoothState.on) {
         ScanBleDoughDevice(flutterBlue);
      }
    });
  }

  ScanBleDoughDevice(FlutterBlue flutterBlue) async {
    String str = 'N/A';

    // Start scanning
    debugPrint('Start scanning for devices.');

    // Listen to scan results
    StreamSubscription<List<ScanResult>> scanSub = flutterBlue.scanResults.listen((results) async {
      // do something with scan results
      for (ScanResult r in results) {
        debugPrint('\'${r.device.name}\' with rssi: ${r.rssi}');

        if (r.device.name == DOUGH_DEVICE_NAME) {
          asiDoughDevice = r.device;
          str = asiDoughDevice.name;
          debugPrint('${str} GOT Asi Dough Device, Connecting....');

          // Stop scanning
          debugPrint('Stop scanning (found my device');
          await flutterBlue.stopScan();

          // Subscribe to connection changes
          StreamSubscription<BluetoothDeviceState> deviceStateSubscription = r.device.state.listen((state) async {
            setState(() {
              asiDoughDeviceState = state;
            });
            debugPrint('Device status changed to \'${state.name}\'');

            if (state == BluetoothDeviceState.connected) {
              debugPrint('Connected');

              //Get Service
              await discoverBleDoughServices();
            } else if (state == BluetoothDeviceState.disconnected) {
              debugPrint('Disconnected !!');
              if (!statusChangeByUser) {
                await r.device.connect();
              }
            }
          });

          break;
        }
      }
    });

    flutterBlue.startScan(timeout: const Duration(seconds: 4));
  }

  discoverBleDoughServices() async {
    List<BluetoothService> services = await asiDoughDevice.discoverServices();

    //Look for Dough Height Service
    for (var service in services) {
      if (service.uuid.toString().compareTo(DOUGH_HEIGHT_SERVICE_UUID) == 0) {
        debugPrint(' Found Service ${service.uuid}');
        await ReadCharacteristics(service);
      }
    }
  }

  Future<void> ReadCharacteristics(BluetoothService service) async {
    //Get Characteristics
    var characteristics = service.characteristics;
    for (BluetoothCharacteristic character in characteristics) {
      debugPrint('Found Characteristic ${character.uuid}');
      switch (character.uuid.toString()) {
        case CHARACTERISTIC_STATUS_UUID: //ba0f1f90ca0a
          {
            if (character.properties.read) {
              List<int> value = await character.read();
              debugPrint('Read DoughServcieStatus value ${character.uuid} --> $value');
              setState(() {
                StatusMessage statusValue = GetStatusCharacteristics(value);
                doughServcieStatus = DoughServcieStatusEnum.values[statusValue.status];
              });
            }
            if (!character.isNotifying) {
              statusCharSub = character.value.listen((value) {
                debugPrint('Listen DoughServcieStatus Value ${character.uuid} --> $value');
                setState(() {
                  StatusMessage statusValue = GetStatusCharacteristics(value);
                  doughServcieStatus = DoughServcieStatusEnum.values[statusValue.status];
                });
              });
              Future.delayed(const Duration(milliseconds: 1000), () {
                character.setNotifyValue(true);
              });
            }
          }
          break;
        case CHARACTERISTIC_HEIGHT_UUID: //1ccd50817186
          {
            if (character.properties.read) {
              List<int> value = await character.read();
              debugPrint('Read Dough Height ${character.uuid} --> $value');
              setState(() {
                doughHeight = GetIntCharacteristics(value);
              });
            }
            if (!character.isNotifying) {
              heightCharSub = character.value.listen((value) {
                debugPrint('Listen Dough Height ${character.uuid} --> $value');
                setState(() {
                  doughHeight = GetIntCharacteristics(value);
                });
              });
              Future.delayed(const Duration(milliseconds: 1000), () {
                character.setNotifyValue(true);
              });
            }
          }
          break;
        case CHARACTERISTIC_START_UUID: //4375fc7ded5a
          {
            startStopCharactaristics = character;
          }
          break;
        case CHARACTERISTIC_FERMENTATION_UUID: //48868601ec25
          {
            if (character.properties.read) {
              List<int> value = await character.read();
              debugPrint('Read Dough Fermentation Percentage ${character.uuid} --> $value');
              setState(() {
                fermPrecentage = (GetDoubleCharacteristics(value) * 100);
                debugPrint(fermPrecentage.toStringAsFixed(3));
              });
            }
            if (!character.isNotifying) {
              heightCharSub = character.value.listen((value) {
                debugPrint('Listen Dough Fermentation Percentage ${character.uuid} --> $value');
                setState(() {
                  fermPrecentage = (GetDoubleCharacteristics(value) * 100);
                  debugPrint(fermPrecentage.toStringAsFixed(3));
                });
              });
              Future.delayed(const Duration(milliseconds: 1500), () {
                character.setNotifyValue(true);
              });
            }
          }
          break;
      }
    }
  }

  int GetIntCharacteristics(List<int> value) {
    //heightCharSub
    int intValue = 0;
    if (value.isNotEmpty) {
      String stringValue = const AsciiDecoder().convert(value);
      if (stringValue != 'N/A') {
        intValue = int.parse(stringValue);
      }
    }
    return intValue;
  }

  double GetDoubleCharacteristics(List<int> value) {
    //heightCharSub
    double doubleValue = 0.0;
    if ((value.isNotEmpty) && (value.length < 10)) {
      String stringValue = const AsciiDecoder().convert(value);
      if (stringValue != 'N/A') {
        doubleValue = double.parse(stringValue);
      }
    }
    return doubleValue;
  }

  StatusMessage GetStatusCharacteristics(List<int> value) {

    StatusMessage statusValue = StatusMessage.EmptyConstructor();
    if (value.isNotEmpty) {
      String stringValue = const AsciiDecoder().convert(value);
      if (stringValue != 'N/A') {
        final statusMap = jsonDecode(stringValue) as Map<String, dynamic>;
        statusValue = StatusMessage.fromJson(statusMap);
      }
    }
    return statusValue;
  }


  void DisconnectingDevice() {
    debugPrint('Disconnecting from device, remove subscriptions');
    heightCharSub.cancel();
    statusCharSub.cancel();
    asiDoughDevice.disconnect();
  }
}
