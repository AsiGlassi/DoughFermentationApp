import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dough_fermentation/Messages.dart';
import 'package:dough_fermentation/DoughAudioPlayer.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';



const String DOUGH_DEVICE_NAME = "Asi Dough Height";
const String DOUGH_DOUGH_FERMENTATION_SERVICE_UUID = "3ee2ffbe-e236-41f2-9c40-d44563ddc614";
const String CHARACTERISTIC_HEIGHT_UUID = "7daf9c2b-715c-4a1c-b889-1ccd50817186";
const String CHARACTERISTIC_FERMENTATION_UUID = "8d0ca8ce-5c66-4e31-ba1a-48868601ec25";
const String CHARACTERISTIC_STATUS_UUID = "a1990b88-249f-45b2-a0b2-ba0f1f90ca0a";
const String CHARACTERISTIC_SESSION_STATUS_UUID = "90e0676a-eae2-4878-9a6f-61090aac8837";
const String CHARACTERISTIC_CONFIGURATION_UUID = "b164f891-400a-439f-95d2-659973c18df4";

const String CHARACTERISTIC_COMMAND_UUID = "fc70539e-2e17-4cf8-b7e2-4375fc7ded5a";

enum DoughServcieStatusEnum { idle, Fermenting, ReachedDesiredFerm, OverFerm, Error }

final List<Color> doughServcieStatuColors = <Color>[
  const Color.fromARGB(0xFF, 0xFF, 0xFF, 0xFF), //GRB 0xFFFFFF,
  const Color.fromARGB(0xFF, 0xFF, 0xFF, 0x88), //GRB 0xFFFF88
  const Color.fromARGB(0xFF, 0x33, 0xFF, 0x33), //GRB 0x33FF33
  const Color.fromARGB(0xFF, 0xFF, 0x75, 0x33), //GRB 0xFF7533
  const Color.fromARGB(0xFF, 0xEE, 0x33, 0x33), //GRB 0xEE3333
];
const Color deviceConnectedColor = Color.fromARGB(0xFF, 0xAC, 0x61, 0x99); //GRB 0xAC6199

StreamSubscription<BluetoothAdapterState>? adapterStateSubsc = null;
BluetoothDevice? asiDoughDevice = null;
final DoughAudioPlayer audioPlayer = DoughAudioPlayer();

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool statusChangeByUser = false;

  BluetoothAdapterState btState = BluetoothAdapterState.unknown;

  FlutterBluePlus flutterBluePlus = FlutterBluePlus();
  bool isScanning = false;
  BluetoothAdapterState btDeviceState = BluetoothAdapterState.unknown;
  bool serviceConnected = false;
  BluetoothCharacteristic? startStopCharactaristics = null;
  DoughServcieStatusEnum doughServcieStatus = DoughServcieStatusEnum.idle;
  int doughHeight = 0;
  double fermPrecentage = 0.0;
  String errorMessage = '';

  //event subscription
  StreamSubscription<BluetoothConnectionState>? asiDoughConnSubsc = null;
  StreamSubscription<List<int>>? statusCharSubsc = null;
  StreamSubscription<List<int>>? heightCharSubsc = null;
  StreamSubscription<List<int>>? heightPercentageCharSubsc = null;
  StreamSubscription<List<ScanResult>>? scanSubsc = null;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(children: [
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
                      btState == BluetoothAdapterState.off ? Icons.bluetooth_disabled : Icons.bluetooth_outlined,
                      color: btState == BluetoothAdapterState.off ? Colors.redAccent : Colors.blue,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        btState == BluetoothAdapterState.off ? 'BT Off' : 'BT On',
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
                      color: Colors.lightGreen[50], border: Border.all(color: Colors.orange, width: 2.0)),
                  padding: EdgeInsets.all(1.0),
                  margin: const EdgeInsets.symmetric(vertical: 5.0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      //Change device conn status
                      switch (btDeviceState) {
                        case BluetoothAdapterState.unknown:
                        case BluetoothAdapterState.on:
                          //case BluetoothAdapterState.unauthorized:
                          //case BluetoothAdapterState.unavailable:
                          debugPrint('TAP - Scanning for Devices ...');
                          await ScanBleDoughDevice(flutterBluePlus);
                          break;
                        // case BluetoothAdapterState.turningOff:
                        //   {
                        //     debugPrint('Connecting back...');
                        //     await asiDoughDevice.connect();
                        //   }
                        //   break;
                        // case BluetoothAdapterState.off:
                        case BluetoothAdapterState.turningOff:
                          {
                            debugPrint('Disconnecting device');
                            statusChangeByUser = true;
                            DisconnectingDevice();
                          }
                          break;
                      }
                    },
                    child: Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
                      //Device   Icon
                      Icon(
                        size: 30.0,
                        (serviceConnected) ? Icons.bluetooth_connected : Icons.bluetooth_outlined,
                        color: (serviceConnected) ? Colors.blue : Colors.grey,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          (serviceConnected)
                              ? 'Connected'
                              : isScanning
                                  ? 'Connecting ...'
                                  : 'Not Connected',
                          style: const TextStyle(
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
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent[100], // background color
                      foregroundColor: Colors.white, // text color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 5),
                    ),
                    onPressed: IsStartStopDisabled()? null : () {
                      if (serviceConnected) {
                        if ((startStopCharactaristics != null) && serviceConnected) {
                          if (doughServcieStatus == DoughServcieStatusEnum.idle) {
                            debugPrint('Start Fermentation Monitoring.');
                            audioPlayer.PlaySound("StartFermentation");
                            startStopCharactaristics!.write([0x1]);
                          } else if (doughServcieStatus != DoughServcieStatusEnum.Error) {
                            debugPrint('Stop Fermentation Monitoring.');
                            audioPlayer.PlaySound("EndFermentation");
                            startStopCharactaristics!.write([0x0]);
                          } else {
                            null;
                          }
                        } else {
                          null;
                        }
                      };
                    },
                    child: Text(
                        (doughServcieStatus == DoughServcieStatusEnum.idle)
                        ? 'Start'
                        : (doughServcieStatus == DoughServcieStatusEnum.Error)
                          ? 'Error'
                          : 'Stop',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: serviceConnected ? Colors.black : Colors.grey,
                      )
                    )
                  ),
                ),
                //Fermentation Status -   idle, Fermenting, ReachedDesiredFerm, OverFerm, Error
                Container(
                  decoration: BoxDecoration(
                    color: (() {
                      if (doughServcieStatus != DoughServcieStatusEnum.Error) {
                        return doughServcieStatuColors[doughServcieStatus.index];
                      } else {
                        return doughServcieStatuColors[DoughServcieStatusEnum.idle.index];
                      }
                    })(),
                    border: Border.all(color: Colors.lightBlue, width: 2.0)),
                  margin: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Row(mainAxisAlignment: MainAxisAlignment.start, mainAxisSize: MainAxisSize.max, children: [
                    //BT Icon
                    Icon(
                      size: 30.0,
                      doughServcieStatus == DoughServcieStatusEnum.idle
                          ? Icons.hourglass_empty
                          : serviceConnected
                              ? Icons.bluetooth_connected
                              : doughServcieStatus == DoughServcieStatusEnum.Fermenting
                                  ? Icons.hourglass_bottom
                                  : doughServcieStatus == DoughServcieStatusEnum.ReachedDesiredFerm
                                      ? Icons.hourglass_full
                                      : doughServcieStatus == DoughServcieStatusEnum.OverFerm
                                          ? Icons.upload_sharp
                                          : Icons.error_outline,
                      color: Colors.blue,
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Text(
                        doughServcieStatus == DoughServcieStatusEnum.idle
                            ? 'Idle'
                            : doughServcieStatus == DoughServcieStatusEnum.Fermenting
                                ? 'Fermenting'
                                : doughServcieStatus == DoughServcieStatusEnum.ReachedDesiredFerm
                                    ? 'Done'
                                    : doughServcieStatus == DoughServcieStatusEnum.OverFerm
                                        ? 'Over Fermentation'
                                        : 'Error',
                        style: const TextStyle(
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

        //Error
      Visibility(
        visible: (doughServcieStatus == DoughServcieStatusEnum.Error),
        child:Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10.0),
          margin: const EdgeInsets.fromLTRB(10.0, 30.0, 10.0, 10.0),
          color: Colors.pink[50],
          child: Container(
            margin: const EdgeInsets.all(5.0),
            decoration: BoxDecoration(
              color: Colors.cyan[75],
              border: Border.all(
                color: Colors.blueAccent,
              )
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Container(
                    child: Text(
                      '$errorMessage',
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: doughServcieStatus == DoughServcieStatusEnum.Error ? Colors.red : Colors.blue,
                      ),
                    ),
                  ),
                ),
              ]
            )
          ),
          )
      ),
    ]
      )
    );
  }

  bool IsStartStopDisabled() {
    return (!serviceConnected || doughServcieStatus == DoughServcieStatusEnum.Error);
  }

  @override
  void initState() {
    super.initState();

    //set BT logger settings
    FlutterBluePlus.setLogLevel(LogLevel.info, color: false);
    if (adapterStateSubsc != null) {
      // Already subscribed to BT status changes.
      return;
    }

    //listen bluetooth current state
    adapterStateSubsc = FlutterBluePlus.adapterState.listen((state) {
      setState(() {
        btState = state;
      });

      if (state == BluetoothAdapterState.off) {
        //ToDo - Alert user to turn on bluetooth.
        debugPrint('Bluetooth is OFF.');

        // turn on bluetooth ourself if we can
        // for iOS, the user controls bluetooth enable/disable
        if (/*!kIsWeb && */ Platform.isAndroid) {
          // FlutterBluePlus.turnOn();
        }
      } else if (state == BluetoothAdapterState.on) {
        //Get Service
        ScanBleDoughDevice(flutterBluePlus);
      }
    });

    // cancel to prevent duplicate listeners
    // adapterStateSubsc.cancel();
  }

  // Future requestBluetoothPermission() async {
  //   PermissionStatus status = await Permission.bluetoothScan.request();
  //   if (status.isGranted) {
  //     print("Bluetooth scan permission granted");
  //   } else {
  //     print("Bluetooth scan permission denied");
  //   }
  // }

  Future<void> ScanBleDoughDeviceTimer(FlutterBluePlus flutterBluePlus) async {
    var timer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      //found device in last iteration, stop timer
      if (asiDoughDevice != null) {
        //stop conn timer
        timer.cancel();
        return;
      }

      ScanBleDoughDevice(flutterBluePlus);
    });
  }

  Future<void> ScanBleDoughDevice(FlutterBluePlus flutterBluePlus) async {
    bool needToScan = (asiDoughDevice == null);
    bool needToReconnect = (asiDoughDevice != null && asiDoughDevice!.isConnected == false);

    while (needToScan || needToReconnect) {
      //case of enforce scan
      if (needToReconnect) {
        //Object already exist, no need to scan, try to connect
        ConnectDevice(asiDoughDevice!);
        return;
      }

      // Start scanning
      // await requestBluetoothPermission();
      debugPrint('Start scanning for devices.');

      // Listen to scan results
      scanSubsc ??= FlutterBluePlus.onScanResults.listen(
        (results) async {
          debugPrint('Device Scan Result size;${results.length}');

          if (results.isNotEmpty) {
            ScanResult result = results.last; // the most recently found device

            debugPrint('\'${result.device.platformName}\' with rssi: ${result.rssi}');

            if (result.device.platformName == DOUGH_DEVICE_NAME) {
              asiDoughDevice = result.device;
              await asiDoughDevice!.connect();
              serviceConnected = true;
              audioPlayer.PlaySound("Connected");
              debugPrint('\'$asiDoughDevice!.platformName\' Found Asi Dough Device, stop scan and Connect.');

              // Stop scanning
              await FlutterBluePlus.stopScan();

              //Subscribe for device connection/disconnection
              if (asiDoughConnSubsc == null) {
                asiDoughConnSubsc = onDeviceConnectionChange();
              }

              //Connect to the device
              ConnectDevice(asiDoughDevice!);
            }
          }
        },
        onError: (error) => print("Error inn scan results: $error"),
      );
      // cleanup: cancel subscription when scanning stops
      // FlutterBluePlus.cancelWhenScanComplete(scanSubsc!);

      //start actual scan
      isScanning = true;
      FlutterBluePlus.startScan(
              // withServices:[Guid(DOUGH_HEIGHT_SERVICE_UUID)], // match any of the specified services
              withNames: ["Asi Dough Height"],
              // *or* any of the specified names (withKeywords)
              timeout: const Duration(seconds: 5))
          .catchError((error) {
        print("Error starting scan: $error");
      });

      // wait for scanning to stop
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
      setState(() {
        isScanning = false;
      });

      // No device found, wait for 30 seconds before scanning again
      await Future.delayed(const Duration(seconds: 30));

      needToScan = (asiDoughDevice == null);
      needToReconnect = (asiDoughDevice != null && asiDoughDevice!.isConnected == false);
    }
  }

  StreamSubscription<BluetoothConnectionState> onDeviceConnectionChange() {
    return asiDoughDevice!.connectionState.listen((state) {
      debugPrint('Device status changed to \'${state.name}\'');

      if (state == BluetoothConnectionState.connected) {
        // print("Connection established with Asi Dough Device.");

        setState(() {
          serviceConnected = true;
          audioPlayer.PlaySound("Connected");
        });

        //set device settings
        if (Platform.isAndroid) {
          final subscription = asiDoughDevice!.mtu.listen((int mtu) {
            // iOS: initial value is always 23, but iOS will quickly negotiate a higher value
            int mtuNow = asiDoughDevice!.mtuNow;
            debugPrint('Device MTU changed to $mtu , $mtuNow');
          });

          //Request long messages
          asiDoughDevice!.requestMtu(512);

          // asiDoughDevice.requestConnectionPriority();
        }

        //look for services
        discoverBleDoughServices();

      } else if (state == BluetoothConnectionState.disconnected) {
        if (!statusChangeByUser) {
          setState(() {
            serviceConnected = false;
            audioPlayer.PlaySound("DisConnected");
          });

          Timer.periodic(const Duration(seconds: 7), (timer) {
            //try to reconnect
            if (!serviceConnected) {
              debugPrint('Timer \'${timer.tick}\' try to connect');
              //Connect to the device
              ConnectDevice(asiDoughDevice!);
            } else {
              debugPrint('Connected cancel timer.');
              timer.cancel();
            }
          });
        }
      }
    });
  }

  Future<void> ConnectDevice(BluetoothDevice device) async {
    try {
      await asiDoughDevice!
          .connect(autoConnect: true, mtu: null, timeout: const Duration(seconds: 15))
          .catchError((error) {
        print("Failed to connect Asi Dough Device: $error");
      });
    } catch (e) {
      debugPrint("Connection failed: $e");
    }
  }

  void disconnect() {
    asiDoughDevice?.disconnect();
    asiDoughDevice = null;
  }

  discoverBleDoughServices() async {
    if (asiDoughDevice == null) return;
    List<BluetoothService>? services = await asiDoughDevice?.discoverServices();

    //Look for Dough Height Service
    for (var service in services!) {
      if (service.uuid.toString().compareTo(DOUGH_DOUGH_FERMENTATION_SERVICE_UUID) == 0) {
        //Service Found, Mark Connected
        serviceConnected = true;
        debugPrint('Found the Dough Height Service');
        audioPlayer.PlaySound("Connected");
        await ReadCharacteristics(service);
      }
    }
  }

  Future<void> ReadCharacteristics(BluetoothService service) async {
    //Get Characteristics
    List<BluetoothCharacteristic> characteristics = service.characteristics;
    for (BluetoothCharacteristic character in characteristics) {
      debugPrint('Found Characteristic ${character.uuid}');
      switch (character.uuid.toString()) {
        case CHARACTERISTIC_STATUS_UUID: //ba0f1f90ca0a
          {
            if (character.properties.read) {
              List<int> value = await character.read();
              StatusMessage statusValue = GetStatusCharacteristics(value);
              await ExecuteCharacteristicStatus(statusValue, false);
            }
            if (!character.isNotifying) {
              statusCharSubsc?.cancel();
              statusCharSubsc = character.onValueReceived.listen((value) {
                StatusMessage statusValue = GetStatusCharacteristics(value);
                 ExecuteCharacteristicStatus(statusValue, false);
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
              int intTmpVal = GetIntCharacteristics(value);
              debugPrint('Read Dough Height: \'$intTmpVal\'');
              setState(() {
                doughHeight = intTmpVal;
              });
            }
            if (!character.isNotifying) {
              heightCharSubsc?.cancel();
              heightCharSubsc = character.onValueReceived.listen((value) {
                int intTmpVal = GetIntCharacteristics(value);
                debugPrint('Listen Dough Height: \'$intTmpVal\'');
                setState(() {
                  doughHeight = intTmpVal;
                });
              });
              Future.delayed(const Duration(milliseconds: 1000), () {
                character.setNotifyValue(true);
              });
            }
          }
          break;
        case CHARACTERISTIC_COMMAND_UUID: //4375fc7ded5a
          {
            startStopCharactaristics = character;
          }
          break;
        case CHARACTERISTIC_FERMENTATION_UUID: //48868601ec25
          {
            if (character.properties.read) {
              List<int> value = await character.read();
              double dblTempVal = (GetDoubleCharacteristics(value) * 100);
              debugPrint('Read Dough Fermentation Percentage: \'${dblTempVal.toStringAsFixed(3)}\'');
              setState(() {
                fermPrecentage = dblTempVal;
              });
            }
            if (!character.isNotifying) {
              heightPercentageCharSubsc?.cancel();
              heightPercentageCharSubsc = character.onValueReceived.listen((value) {
                double dblTempVal = (GetDoubleCharacteristics(value) * 100);
                debugPrint('Listen Dough Fermentation Percentage: \'${dblTempVal.toStringAsFixed(3)}\'');
                setState(() {
                  fermPrecentage = dblTempVal;
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

  //Helper Characteristic Status
  Future<void> ExecuteCharacteristicStatus(StatusMessage statusValue, bool notify) async {
    debugPrint(
        '${notify?'Listen':'read'} Dough Service Status Status \'${DoughServcieStatusEnum.values[statusValue.status]}\', Message: \'${statusValue.message}\'');
    setState(() {
      DoughServcieStatusEnum newStatus = DoughServcieStatusEnum.values[statusValue.status];
      if (doughServcieStatus != newStatus) {
        switch (newStatus) {
          case DoughServcieStatusEnum.Error:
            audioPlayer.PlaySound("Error");
            break;
          case DoughServcieStatusEnum.OverFerm:
            audioPlayer.PlaySound("OverFerm");
            break;
          case DoughServcieStatusEnum.ReachedDesiredFerm:
            audioPlayer.PlaySound("ReachedDesiredFerm");
            break;
        }
      }
      doughServcieStatus = newStatus;
    });
  }

  int GetIntCharacteristics(List<int> value) {
    //heightCharSub
    int intValue = 0;
    if (value.isNotEmpty) {
      try {
        String stringValue = const AsciiDecoder().convert(value);
        if (stringValue != 'N/A') {
          intValue = int.parse(stringValue);
        }
      } catch (ex) {
        debugPrint('Parse Int characteristics Exception: \'${ex}\'');
      }
    }
    return intValue;
  }

  double GetDoubleCharacteristics(List<int> value) {
    //heightCharSub
    double doubleValue = 0.0;
    if ((value.isNotEmpty) && (value.length < 10)) {
      try {
        String stringValue = const AsciiDecoder().convert(value);
        if (stringValue != 'N/A') {
          doubleValue = double.parse(stringValue);
        }
      } catch (ex) {
        debugPrint('Parse Double characteristics Exception: \'${ex}\'');
      }
    }
    return doubleValue;
  }

  StatusMessage GetStatusCharacteristics(List<int> value) {
    StatusMessage statusValue = StatusMessage.EmptyConstructor();
    if (value.isNotEmpty) {
      try {
        String stringValue = const AsciiDecoder().convert(value);
        if (stringValue != 'N/A') {
          final statusMap = jsonDecode(stringValue) as Map<String, dynamic>;
          statusValue = StatusMessage.fromJson(statusMap);
        }
      } catch (ex) {
        debugPrint('Parse Status characteristics Exception: \'${ex}\'');
      }
    }
    return statusValue;
  }

  void DisconnectingDevice() {
    debugPrint('Disconnecting from device, remove subscriptions');
    // heightCharSubsc.cancel();
    // statusCharSubsc.cancel();
    asiDoughDevice?.disconnect(); //ToDo - does it affect the reconnect?
  }

  // @override
  // void dispose() {
  //   deviceStateSubscription.cancel();
  // player.dispose();
  //   super.dispose();
  // }
}
