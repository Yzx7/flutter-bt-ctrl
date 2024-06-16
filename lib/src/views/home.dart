import 'dart:async';
import 'dart:math';
import 'package:blueautoy/src/provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:provider/provider.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.color,
    required this.text,
    this.onTap,
  });

  final Color color;
  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 150.0,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(fontSize: 18.0, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // final _bluetooth = FlutterBluetoothSerial.instance;
  // BluetoothConnection? _connection;

  int times = 0;
  int angleInput1 = 90;

  double inputSL1 = 90;
  double inputSL2 = 90;
  double inputSL3 = 90;

  Timer? _timerS1;
  Timer? _timerS2;
  Timer? _timerS3;

  // void _receiveData() {
  //   _connection?.input?.listen((event) {
  //     if (String.fromCharCodes(event) == "p") {
  //       setState(() => times = times + 1);
  //     }
  //   });
  // }

  @override
  void initState() {
    super.initState();
    // FlutterBluePlus.setLogLevel(LogLevel.none, color: false);

    // _requestPermission();
  }

  double? degree;
  double? dist;
  final int period1 = 200;

  @override
  Widget build(BuildContext context) {
    MainProvider ctxRead = context.read<MainProvider>();
    MainProvider ctxWatch = context.watch<MainProvider>();

    FlutterSliderTrackBar trackbarStyle = FlutterSliderTrackBar(
      inactiveTrackBar: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.2),
        border: Border.all(width: 3, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
      ),
      activeTrackBarHeight: 16,
      inactiveTrackBarHeight: 16,
      activeTrackBar: BoxDecoration(borderRadius: BorderRadius.circular(4), color: Theme.of(context).colorScheme.primary),
    );

    Future loadBleBTNFunc() async {
      if (!ctxWatch.bluetoothState) {
        await ctxRead.requestBTPermission();
      }
      if (!ctxWatch.bluetoothState) {
        return;
      }
      showDialog(
          context: context,
          builder: (context) {
            return const Center(child: CircularProgressIndicator());
          });
      if (ctxWatch.btIsConected) {
        ctxRead.btDeviceDisconect();
        Navigator.of(context).pop();
        return;
      }
      ctxRead.getDevices();
      Navigator.of(context).pop();

      showModalBottomSheet(
          context: context,
          useSafeArea: true,
          constraints: const BoxConstraints(
            maxHeight: 650,
          ),
          scrollControlDisabledMaxHeightRatio: 1,
          builder: (context) {
            return SizedBox(
              height: 1000,
              child: Center(
                child: ListenableBuilder(
                    listenable: ctxWatch,
                    builder: (context, snapshot) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        child:
                            Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth_searching,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 4,
                                child: Text(
                                  "Dispositivos Bluetooth",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Theme.of(context).colorScheme.primary,
                                    // color: Colors.black54
                                  ),
                                ),
                              ),
                              IconButton(
                                  color: Theme.of(context).colorScheme.primary,
                                  onPressed: () async {
                                    ctxRead.getDevices();
                                  },
                                  icon: const Icon(Icons.refresh)),
                            ],
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                                child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                  for (final device in ctxWatch.devices)
                                    ListTile(
                                      title: Text(device.device.advName),
                                      trailing: TextButton(
                                        child: Text(device.device.isConnected ? "desconectar" : 'conectar'),
                                        onPressed: () async {
                                          try {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return const Center(child: CircularProgressIndicator());
                                                });
                                            await ctxRead.btConnectTo(device.device);
                                            Navigator.of(context).pop();
                                            // _receiveData();
                                          } catch (e) {
                                            print(e);
                                          }
                                        },
                                      ),
                                    ),
                                  Divider(),
                                  Text("Dispos"),
                                  for (final device in ctxWatch.systemdevices)
                                    ListTile(
                                      title: Text(device.advName + " | " + device.platformName),
                                      trailing: TextButton(
                                        child: Text(device.isConnected ? "desconectar" : 'conectar'),
                                        onPressed: () async {
                                          try {
                                            showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return const Center(child: CircularProgressIndicator());
                                                });
                                            await ctxRead.btConnectTo(device);
                                            Navigator.of(context).pop();
                                            // _receiveData();
                                          } catch (e) {
                                            print(e);
                                          }
                                        },
                                      ),
                                    ),
                                ])),
                          )
                        ]),
                      );
                    }),
              ),
            );
          });
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('BLE-ESP32'),
      ),
      body: ListenableBuilder(
          listenable: ctxWatch,
          builder: (context, snapshot) {
            return Column(
              // crossAxisAlignment: CrossAxisAlignment.stretch,
              // mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      Center(
                        child: IconButton(
                          onPressed: loadBleBTNFunc,
                          icon: const Icon(Icons.bluetooth),
                          style: ButtonStyle(
                              // iconSize: !ctxWatch.btIsConected ? const MaterialStatePropertyAll(100) : null,
                              backgroundColor: ctxWatch.btIsConected
                                  ? MaterialStatePropertyAll(Theme.of(context).colorScheme.primary.withOpacity(0.2))
                                  : MaterialStatePropertyAll(Theme.of(context).colorScheme.onBackground.withOpacity(0.1))),
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Text("Conectado a: ${ctxWatch.deviceConnected?.advName ?? "ninguno"}"),
                    ],
                  ),
                ),

                // _controlBT(),
                // _infoDevice(),
                const SizedBox(height: 60),

                Expanded(
                    child: Container(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Center(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 180,
                                    child: FlutterSlider(
                                      onDragStarted: (handlerIndex, lowerValue, upperValue) {
                                        _timerS1 = Timer.periodic(Duration(milliseconds: period1), (timer) {
                                          print("SHOULDER:$inputSL1");
                                          ctxRead.sendData("SHOULDER:$inputSL1");
                                        });
                                      },
                                      onDragCompleted: (handlerIndex, lowerValue, upperValue) {
                                        ctxRead.sendData("SHOULDER:$lowerValue");
                                        if (_timerS1 != null) {
                                          _timerS1!.cancel();
                                          _timerS1 = null;
                                        }
                                      },
                                      trackBar: trackbarStyle,
                                      axis: Axis.vertical,
                                      rtl: true,
                                      values: [inputSL1],
                                      max: 180,
                                      min: 0,
                                      // trackBar: FlutterSliderTrackBar(inactiveDisabledTrackBarColor: Colors.red),
                                      step: const FlutterSliderStep(step: 10),
                                      onDragging: (handlerIndex, lowerValue, upperValue) {
                                        if (inputSL1 != lowerValue) {
                                          print(lowerValue);
                                          setState(() {
                                            inputSL1 = lowerValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  Text("$inputSL1")
                                ],
                              ),
                              const SizedBox(width: 50),
                              Column(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 180,
                                    child: FlutterSlider(
                                      onDragStarted: (handlerIndex, lowerValue, upperValue) {
                                        _timerS2 = Timer.periodic(Duration(milliseconds: period1), (timer) {
                                          print("ELBOW:$inputSL2");
                                          ctxRead.sendData("ELBOW:$inputSL2");
                                        });
                                      },
                                      onDragCompleted: (handlerIndex, lowerValue, upperValue) {
                                        ctxRead.sendData("ELBOW:$lowerValue");
                                        if (_timerS2 != null) {
                                          _timerS2!.cancel();
                                          _timerS2 = null;
                                        }
                                      },
                                      trackBar: trackbarStyle,
                                      axis: Axis.vertical,
                                      values: [inputSL2],
                                      max: 180,
                                      min: 0,
                                      rtl: true,
                                      step: const FlutterSliderStep(step: 10),
                                      onDragging: (handlerIndex, lowerValue, upperValue) {
                                        if (inputSL2 != lowerValue) {
                                          print(lowerValue);
                                          setState(() {
                                            inputSL2 = lowerValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  Text("$inputSL2")
                                ],
                              ),
                              const SizedBox(width: 50),
                              Column(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 180,
                                    child: FlutterSlider(
                                      onDragStarted: (handlerIndex, lowerValue, upperValue) {
                                        _timerS3 = Timer.periodic(Duration(milliseconds: period1), (timer) {
                                          print("WRIST:$inputSL3");
                                          ctxRead.sendData("WRIST:$inputSL3");
                                        });
                                      },
                                      onDragCompleted: (handlerIndex, lowerValue, upperValue) {
                                        ctxRead.sendData("WRIST:$lowerValue");
                                        if (_timerS3 != null) {
                                          _timerS3!.cancel();
                                          _timerS3 = null;
                                        }
                                      },
                                      trackBar: trackbarStyle,
                                      axis: Axis.vertical,
                                      values: [inputSL3],
                                      max: 180,
                                      min: 0,
                                      rtl: true,
                                      step: const FlutterSliderStep(step: 10),
                                      onDragging: (handlerIndex, lowerValue, upperValue) {
                                        if (inputSL3 != lowerValue) {
                                          print(lowerValue);
                                          setState(() {
                                            inputSL3 = lowerValue;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  Text("$inputSL3")
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Center(
                          child: Container(
                            // margin: EdgeInsets.only(top: 60, left: 60),
                            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(10)),
                            width: 40,
                            height: 10,
                            child: Transform(
                              origin: const Offset(20, 110),
                              transform: Matrix4.rotationZ(pi / 2 - angleInput1.abs() * pi / 180),
                              child: Container(
                                decoration:
                                    BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(10)),
                                width: 100,
                                height: 10,
                              ),
                            ),
                          ),
                        ),
                        Center(
                          child: Joystick(
                            base: JoystickBase(
                              decoration: JoystickBaseDecoration(
                                boxShadows: [],
                                // color: Theme.of(context).colorScheme.onBackground,
                                color: Theme.of(context).colorScheme.onBackground,
                                drawOuterCircle: false,
                              ),
                              arrowsDecoration: JoystickArrowsDecoration(
                                color: Colors.blue,
                              ),
                            ),
                            period: Duration(milliseconds: period1),
                            listener: (details) {
                              int angleres = (-atan2(details.y, details.x) * 180 / pi).round();
                              if (angleres == 0 && (angleres - angleInput1).abs() > 20) {
                                return;
                              }
                              print(details.x);
                              // print(details.y);
                              // period1 = (pow((1 - sqrt(details.x * details.x + details.y * details.y)), 2) * 100).round() + 5;
                              // print(period1);
                              // print(DateTime.now().microsecondsSinceEpoch);

                              print(angleres);

                              ctxRead.sendData("BASE:$angleres");

                              setState(() => angleInput1 = angleres);

                              // if (details.x < 0) {
                              //   ctxRead.sendData("8");
                              // }
                              // if (details.x > 0) {
                              //   ctxRead.sendData("7");
                              // }

                              // if (details.y > 0) {
                              //   ctxRead.sendData("9");
                              // }
                              // if (details.y < 0) {
                              //   ctxRead.sendData("10");
                              // }

                              // 8<=>7
                            },
                          ),
                        ),
                        Text("$angleInput1°"),
                        SizedBox(height: 10),
                        Text(
                          "<Yr/>",
                          style: TextStyle(fontSize: 20, color: Colors.white.withOpacity(0.2), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ))

                // _inputSerial(),
                // _buttons(),
              ],
            );
          }),
    );
  }

  // Widget _controlBT() {
  //   return SwitchListTile(
  //     value: _bluetoothState,
  //     onChanged: (bool value) async {
  //       if (value) {
  //         await _bluetooth.requestEnable();
  //       } else {
  //         await _bluetooth.requestDisable();
  //       }
  //     },
  //     tileColor: Colors.black26,
  //     title: Text(
  //       _bluetoothState ? "Bluetooth encendido" : "Bluetooth apagado",
  //     ),
  //   );
  // }

  // Widget _infoDevice() {
  //   return ListTile(
  //     tileColor: Colors.black12,
  //     title: Text("Conectado a: ${_deviceConnected?.name ?? "ninguno"}"),
  //     trailing: _connection?.isConnected ?? false
  //         ? TextButton(
  //             onPressed: () async {
  //               await _connection?.finish();
  //               setState(() => _deviceConnected = null);
  //             },
  //             child: const Text("Desconectar"),
  //           )
  //         : TextButton(
  //             onPressed: _getDevices,
  //             child: const Text("Ver dispositivos"),
  //           ),
  //   );
  // }

  // Widget _listDevices() {
  //   return _isConnecting
  //       ? const Center(child: CircularProgressIndicator())
  //       : SingleChildScrollView(
  //           child: Container(
  //             color: Colors.grey.shade100,
  //             child: Column(
  //               children: [
  //                 ...[
  //                   for (final device in _devices)
  //                     ListTile(
  //                       title: Text(device.name ?? device.address),
  //                       trailing: TextButton(
  //                         child: const Text('conectar'),
  //                         onPressed: () async {
  //                           try {
  //                             setState(() => _isConnecting = true);

  //                             _connection = await BluetoothConnection.toAddress(device.address);
  //                             _deviceConnected = device;
  //                             _devices = [];

  //                             _receiveData();
  //                           } catch (e) {
  //                             print(e);
  //                           }

  //                           _isConnecting = false;
  //                           setState(() {});
  //                         },
  //                       ),
  //                     )
  //                 ]
  //               ],
  //             ),
  //           ),
  //         );
  // }

  // Widget _inputSerial() {
  //   return ListTile(
  //     trailing: TextButton(
  //       child: const Text('reiniciar'),
  //       onPressed: () => setState(() => times = 0),
  //     ),
  //     title: Padding(
  //       padding: const EdgeInsets.symmetric(vertical: 16.0),
  //       child: Text(
  //         "Pulsador presionado (x$times)",
  //         style: const TextStyle(fontSize: 18.0),
  //       ),
  //     ),
  //   );
  // }

  // Widget _buttons() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 8.0),
  //     color: Colors.black12,
  //     child: Column(
  //       children: [
  //         const Text('Controles para LED', style: TextStyle(fontSize: 18.0)),
  //         const SizedBox(height: 16.0),
  //         Row(
  //           children: [
  //             Expanded(
  //               child: ActionButton(
  //                 text: "Encender",
  //                 color: Colors.green,
  //                 onTap: () => ctxRead.sendData("1"),
  //               ),
  //             ),
  //             const SizedBox(width: 8.0),
  //             Expanded(
  //               child: ActionButton(
  //                 color: Colors.red,
  //                 text: "Apagar",
  //                 onTap: () => ctxRead.sendData("0"),
  //               ),
  //             ),
  //           ],
  //         ),
  //       ],
  //     ),
  //   );
  // }
}
