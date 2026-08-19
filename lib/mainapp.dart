import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

import 'package:wireguard_flutter_plus/wireguard_flutter_platform_interface.dart';

import 'vpn_service.dart';
import 'utils/utils.dart';


void initTray() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await windowManager.ensureInitialized();
      await windowManager.setPreventClose(true);
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override 
  State<MainApp> createState() => _MyAppState();
}

class _MyAppState extends State<MainApp> with TrayListener, WindowListener {

  bool isVPNOn = false;

  String _serverAddress = "";
  String confPath = "";
  String filename = "";
  String logContent = "";

  double totalUpload = 0;
  double totalDownload = 0;
  double uploadSpeed = 0;
  double downloadSpeed = 0;

  final List<FlSpot> _sentSpots =[const FlSpot(0, 0)];
  final List<FlSpot> _receivedSpots = [const FlSpot(0, 0)];

  double _maxXSent = 10;
  double _maxYSent = 64;
  double _maxXReceived = 10;
  double _maxYReceived = 64;
  int _tickCount = 0;

  bool _canUpdateChart = true;
  final Duration _updateInterval = const Duration(seconds: 3);

  int _totalSecondsConnected = 0;
  
  final VpnService _vpnService = VpnService();
  VpnStage _stage = VpnStage.disconnected;

  bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  String? _getIconPathByStage() {
    const String pathIconInactive = "assets/icon_inactive.svg";
    const String pathIconActive = "assets/icon_active.svg";
    const String pathIconInProgress = "assets/icon_in_progress.svg";

    const Map<VpnStage, String> stageIcons = {
      VpnStage.disconnecting: pathIconInactive,
      VpnStage.disconnected: pathIconInactive,
      VpnStage.preparing: pathIconInProgress,
      VpnStage.connecting: pathIconInProgress,
      VpnStage.connected: pathIconActive,
    };

    return stageIcons[_stage];
  }
  String? _getTextStage() {
    const Map<VpnStage, String> stageTexts = {
      VpnStage.disconnecting: "Disconnecting...",
      VpnStage.disconnected: "Disconnected",
      VpnStage.preparing: "Connecting...",
      VpnStage.connecting: "Connecting...",
      VpnStage.connected: "Connected",
    };

    return stageTexts[_stage];
  }

  final ScrollController _logScrollController = ScrollController();
  final TextEditingController _controllerServerAddress = TextEditingController();
 

  void init() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      confPath = prefs.getString("confPath")!;
      filename = prefs.getString("filename")!;
      _serverAddress = prefs.getString("serverAddress")!;
      _controllerServerAddress.text = _serverAddress;
    });
  }

  @override
  void initState() {
    super.initState();

    init();
    _vpnService.initializeVpn();
    _vpnService.vpnStageStream.listen((stage) {
      if (!mounted) return;

      setState(() {
        logContent += '${DateTime.now()}: Stage changed to $stage\n';

        _stage = stage;
        if (stage == VpnStage.connected) {
          isVPNOn = true;
        } 
        else if (stage == VpnStage.disconnecting || 
                stage == VpnStage.disconnected || 
                stage == VpnStage.denied ||
                stage == VpnStage.noConnection) {
          isVPNOn = false;
        }
      });
    });
    _vpnService.trafficStatsSnapshot.listen((Map<String, dynamic> stats) {
      if (!mounted) return;

      Timer(const Duration(seconds: 1), () {
        setState(() {
          _totalSecondsConnected = isVPNOn ? _totalSecondsConnected + 1 : 0;
        });
      });
      setState(() {
        totalUpload = isVPNOn ? (stats['totalUpload'] ?? 0).toDouble() : 0;
        totalDownload = isVPNOn ? (stats['totalDownload'] ?? 0).toDouble() : 0;
        uploadSpeed = isVPNOn ? (stats['uploadSpeed'] ?? 0).toDouble() : 0;
        downloadSpeed = isVPNOn ? (stats['downloadSpeed'] ?? 0).toDouble() : 0;
      });

      if (!_canUpdateChart) return;
      _canUpdateChart = false;

      setState(() {
        _tickCount += 3;
        _sentSpots.add(FlSpot(_tickCount.toDouble(), totalUpload));
        _receivedSpots.add(FlSpot(_tickCount.toDouble(), totalDownload));

        if (_sentSpots.length > 15) {
          _sentSpots.removeAt(0);
          _receivedSpots.removeAt(0);
        }
        if (_tickCount > 10) {
          _maxXSent = _tickCount.toDouble();
          _maxXReceived = _tickCount.toDouble();
        }
        if (totalUpload > _maxYSent) {
          _maxYSent = totalUpload * 1.2;
          _maxYReceived = totalDownload * 1.2;
        }
      });
      Timer(_updateInterval, () {
        _canUpdateChart = true;
      });
    });

    if (isDesktop) {
      trayManager.addListener(this);
      windowManager.addListener(this);
      _initTray();
    }
  }
  @override void dispose() {
     if (isDesktop) {
      trayManager.removeListener(this);
      windowManager.removeListener(this);
    }

    _logScrollController.dispose();
    _controllerServerAddress.dispose(); 
    super.dispose();
  }
  Future<void> _initTray() async {
    await trayManager.setIcon(
      Platform.isWindows ? "icon/icon.ico" : "icon/icon.png"
    );

    await trayManager.setToolTip("VPN4k");

    Menu menu = Menu(
      items: [
        MenuItem(key: "show_window", label: "Show window"),
        MenuItem(key: "toggle_vpn", label: "Toggle VPN"),
        MenuItem(key: "quit", label: "Quit"),
      ]
    );

    await trayManager.setContextMenu(menu);
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      await windowManager.hide();
    }
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
    super.onTrayIconMouseDown();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    if(menuItem.key == "show_window") {
      await windowManager.show();
      await windowManager.focus();
    }
    else if(menuItem.key == "toggle_vpn") {
      setState(() {
        isVPNOn = !isVPNOn;
      });
    }
    else {
      await windowManager.setPreventClose(false);
      disconnectVPN();
      exit(0);
    }

    super.onTrayMenuItemClick(menuItem);
  }

  Future<void> connectVpn() async {
    if (confPath.isNotEmpty) {
      File file = File(confPath);
      String fileContent = await file.readAsString();
      _vpnService.connectVpn(_serverAddress, fileContent);
    } 
  }
  void disconnectVPN() {
    _vpnService.disconnectVpn();
  }

  Future<void> pickAndLoadFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: [ ".conf" ]);

    if (result != null) {
      PlatformFile file = result.files.single;
      if(file.extension! != ".conf")
      {
        setState(() {
          confPath = file.path!;
          filename = file.name;
        });
        final prefs = await SharedPreferences.getInstance();
        prefs.setString("confPath", confPath);
        prefs.setString("filename", filename);
      }  
    }
  }

  Future<void> openBrowser() async {
    final Uri url = Uri.parse('https://www.bbc.com/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    double availableHeight = MediaQuery.sizeOf(context).height;
    Orientation orientation = MediaQuery.of(context).orientation;

    const Color backgroundAppColor =  Color(0xFF303030);
    const Color backgroundTitleColor =  Color(0xFF212121);
    const Color indicatorColor =  Color(0xFF99BCB7);

    const Color primaryColor = Colors.white;
    const Color secondaryColor = Color(0xFFB8B8B8);

    const Color chartLineColor = Color(0xFF606151);

    const Color buttonActiveColor = Color(0xFF5A595C);
    const Color buttonInactiveColor = Color(0xFF595959);
    const Color textInactiveColor = Color(0xFF7E7E7E);

    return MaterialApp(
      home: DefaultTabController(
        length: 4, 
        child: SafeArea(
          child: Scaffold(
            backgroundColor: backgroundAppColor,
            appBar: AppBar(
              centerTitle: true,
              backgroundColor: backgroundTitleColor,
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("VPN4k", style: TextStyle(color: primaryColor, fontSize: 12)),
                  Text("v 0.1.0", style: TextStyle(color: primaryColor, fontSize: 12))
                ]
              ), 
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(availableHeight / 16),
                child: SizedBox(
                  height: availableHeight / 16,
                  child: Material(
                    color: backgroundAppColor,
                    child: const TabBar(
                      padding: EdgeInsets.zero,
                      labelPadding: EdgeInsets.zero,
                      dividerColor: Colors.transparent,
                      indicatorColor: indicatorColor,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicatorPadding: EdgeInsets.zero, 
                      labelColor: primaryColor,
                      unselectedLabelColor: secondaryColor,
                      tabs: [
                        Tab(text: "HOME", height: double.infinity),
                        Tab(text: "STATS", height: double.infinity),
                        Tab(text: "OPTIONS", height: double.infinity),
                        Tab(text: "LOGS", height: double.infinity)
                      ]
                    ),
                  ), 
                )
              )
            ),
            body: TabBarView(children: [

              Center(
                child: SingleChildScrollView(
                  child: Container(   
                    height: orientation == Orientation.portrait ? availableHeight*0.6 : availableHeight,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Spacer(),
                        Column(
                          spacing: availableHeight / 20,
                          children: [
                            SvgPicture.asset(_getIconPathByStage()!),
                            Text(_getTextStage()!, style: TextStyle(color: secondaryColor, fontSize: 12))
                          ],
                        ),
                        Spacer(),
                      ]
                    )  
                  )
                ),
              ),

              SingleChildScrollView(
                child: Container(
                  height: orientation == Orientation.portrait ? availableHeight*0.6 : availableHeight,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: 10, right: 10, top: 10),
                        child: Text(isVPNOn ? "Connected: ${formatSecondsToTime(_totalSecondsConnected)}" : "Disconnected", style: TextStyle(color: secondaryColor))
                      ),
                      Divider(
                        color: primaryColor
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text("Total upload", style: TextStyle(color: secondaryColor)),
                                Spacer(),
                                Text("$totalUpload KiB", style: TextStyle(color: secondaryColor))
                              ],
                            ),
                            Row(
                              children: [
                                Text("Upload speed", style: TextStyle(color: secondaryColor)),
                                Spacer(),
                                Text("$totalUpload B/s", style: TextStyle(color: secondaryColor))
                              ],
                            ),
                            SizedBox(
                              height: 100,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawHorizontalLine: true,
                                    drawVerticalLine: true,
                                    getDrawingHorizontalLine: (value) {
                                      return const FlLine(
                                        color: Colors.grey,
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return const FlLine(
                                        color: Colors.grey,
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: const FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  minX: _sentSpots.first.x,
                                  maxX: _maxXSent,
                                  minY: 0,
                                  maxY: _maxYSent,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _sentSpots,
                                      isCurved: false,
                                      color: chartLineColor,
                                      barWidth: 2,
                                      dotData: const FlDotData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Text("Total download", style: TextStyle(color: secondaryColor)),
                                Spacer(),
                                Text("$totalDownload KiB", style: TextStyle(color: secondaryColor))
                              ],
                            ),
                            Row(
                              children: [
                                Text("Download speed", style: TextStyle(color: secondaryColor)),
                                Spacer(),
                                Text("$totalUpload B/s", style: TextStyle(color: secondaryColor))
                              ],
                            ),
                            SizedBox(
                              height: 100,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawHorizontalLine: true,
                                    drawVerticalLine: true,
                                    getDrawingHorizontalLine: (value) {
                                      return const FlLine(
                                        color: Colors.grey,
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return const FlLine(
                                        color: Colors.grey,
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: const FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  minX: _receivedSpots.first.x,
                                  maxX: _maxXReceived,
                                  minY: 0,
                                  maxY: _maxYReceived,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _receivedSpots,
                                      isCurved: false,
                                      color: chartLineColor,
                                      barWidth: 2,
                                      dotData: const FlDotData(show: false),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      ),
                      Spacer()
                    ],
                  ),
                ),
              ),

              SingleChildScrollView(
                child: Container(
                  height: orientation == Orientation.portrait ? availableHeight*0.6 : availableHeight,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                              Text("Configure", style: TextStyle(color: indicatorColor)),
                              SizedBox(height: 5),
                              Text("Enter server address", style: TextStyle(color: secondaryColor)),
                              SizedBox(height: 5),
                              TextField(
                                controller: _controllerServerAddress,
                                maxLines: 1,
                                style: TextStyle(
                                  color: Colors.white
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: primaryColor
                                    )
                                  ),
                                  fillColor: Colors.transparent,
                                  hintText: 'server address'
                                ),
                                
                                onChanged: (value) async {
                                  setState(() {
                                    _serverAddress = value;
                                  });  
                                },
                                onSubmitted: (value) async {
                                  setState(() {
                                    _serverAddress = value;
                                  });  
                                  final prefs = await SharedPreferences.getInstance();
                                  prefs.setString("serverAddress", _serverAddress);
                                  prefs.setString("filename", filename);
                                },
                                onTapUpOutside: (event) async {
                                  final prefs = await SharedPreferences.getInstance();
                                  prefs.setString("serverAddress", _serverAddress);
                                  prefs.setString("filename", filename);
                                },
                              ),
                              SizedBox(height: 10),
                              Text("The client uses WireGuard\nSelect .conf file to use VPN", style: TextStyle(color: secondaryColor)),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  SizedBox(
                                    width: MediaQuery.sizeOf(context).width / 3,
                                    child: TextButton(
                                      onPressed: () => pickAndLoadFile(), 
                                      style: TextButton.styleFrom(
                                        backgroundColor: buttonActiveColor,
                                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                      ),
                                      child: Text("Import File", style: TextStyle(color: primaryColor))
                                    ),
                                  ),
                                  Spacer(),
                                  Text(filename.isEmpty ? "none selected" : filename, style: TextStyle(color: secondaryColor))
                                ]
                              ),
                          ]
                        ),
                      ),
                      
                      Divider(
                        color: primaryColor
                      ),

                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Information", style: TextStyle(color: indicatorColor)),
                            SizedBox(height: 5),
                            Text("Powered by 4aika_M\nThis is VPN client based on WireGuard.", style: TextStyle(color: secondaryColor)),
                          ]
                        ),
                      )
                    ]
                  ),
                )
              ),
              
              RawScrollbar(
                thumbColor: secondaryColor,
                trackColor: Colors.transparent,
                trackBorderColor: Colors.transparent,
                controller: _logScrollController,
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  controller: _logScrollController,
                  scrollDirection: Axis.vertical,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    child: Text(logContent, style: TextStyle(color: secondaryColor))
                  )
                )
              )
            ]),
            bottomNavigationBar: BottomAppBar(
              color: Colors.transparent,
              padding: EdgeInsets.fromLTRB(5, 0, 5, 5), 
              height: MediaQuery.orientationOf(context) == Orientation.portrait
                ? availableHeight / 18
                : availableHeight / 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        isVPNOn ? disconnectVPN() : connectVpn();
                        setState(() {
                          isVPNOn = !isVPNOn;
                        });
                      }, 
                      style: TextButton.styleFrom(
                        backgroundColor: buttonActiveColor,
                        minimumSize: const Size.fromHeight(double.infinity),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text(isVPNOn ? "Stop" : "Start", style: TextStyle(color: primaryColor))
                    )
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: isVPNOn ? 
                        () => openBrowser()
                        : null, 
                      style: TextButton.styleFrom(
                        backgroundColor: isVPNOn ? buttonActiveColor : buttonInactiveColor,
                        minimumSize: const Size.fromHeight(double.infinity),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text("Open Browser", style: TextStyle(color: isVPNOn ? primaryColor : textInactiveColor))
                    )
                  )
                ]
              )
            )
          ),
        ),
      )
    );
  }
}
