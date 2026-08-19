import 'dart:io';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:wireguard_flutter_plus/wireguard_flutter_platform_interface.dart';

import '../data/services/vpn_service.dart';

class VpnState {
  final bool isVPNOn;
  final String serverAddress;
  final String confPath;
  final String filename;
  final String logContent;
  final double totalUpload;
  final double totalDownload;
  final double uploadSpeed;
  final double downloadSpeed;
  final List<FlSpot> sentSpots;
  final List<FlSpot> receivedSpots;
  final double maxXSent;
  final double maxYSent;
  final double maxXReceived;
  final double maxYReceived;
  final int tickCount;
  final bool canUpdateChart;
  final int totalSecondsConnected;
  final VpnStage stage;

  VpnState({
    this.isVPNOn = false,
    this.serverAddress = "",
    this.confPath = "",
    this.filename = "",
    this.logContent = "",
    this.totalUpload = 0,
    this.totalDownload = 0,
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
    List<FlSpot>? sentSpots,
    List<FlSpot>? receivedSpots,
    this.maxXSent = 10,
    this.maxYSent = 64,
    this.maxXReceived = 10,
    this.maxYReceived = 64,
    this.tickCount = 0,
    this.canUpdateChart = true,
    this.totalSecondsConnected = 0,
    this.stage = VpnStage.disconnected,
  })  : sentSpots = sentSpots ?? [const FlSpot(0, 0)],
        receivedSpots = receivedSpots ?? [const FlSpot(0, 0)];

  VpnState copyWith({
    bool? isVPNOn,
    String? serverAddress,
    String? confPath,
    String? filename,
    String? logContent,
    double? totalUpload,
    double? totalDownload,
    double? uploadSpeed,
    double? downloadSpeed,
    List<FlSpot>? sentSpots,
    List<FlSpot>? receivedSpots,
    double? maxXSent,
    double? maxYSent,
    double? maxXReceived,
    double? maxYReceived,
    int? tickCount,
    bool? canUpdateChart,
    int? totalSecondsConnected,
    VpnStage? stage,
  }) {
    return VpnState(
      isVPNOn: isVPNOn ?? this.isVPNOn,
      serverAddress: serverAddress ?? this.serverAddress,
      confPath: confPath ?? this.confPath,
      filename: filename ?? this.filename,
      logContent: logContent ?? this.logContent,
      totalUpload: totalUpload ?? this.totalUpload,
      totalDownload: totalDownload ?? this.totalDownload,
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      sentSpots: sentSpots ?? this.sentSpots,
      receivedSpots: receivedSpots ?? this.receivedSpots,
      maxXSent: maxXSent ?? this.maxXSent,
      maxYSent: maxYSent ?? this.maxYSent,
      maxXReceived: maxXReceived ?? this.maxXReceived,
      maxYReceived: maxYReceived ?? this.maxYReceived,
      tickCount: tickCount ?? this.tickCount,
      canUpdateChart: canUpdateChart ?? this.canUpdateChart,
      totalSecondsConnected: totalSecondsConnected ?? this.totalSecondsConnected,
      stage: stage ?? this.stage,
    );
  }
}

class VpnNotifier extends Notifier<VpnState> {
  final VpnService _vpnService = VpnService();
  StreamSubscription<VpnStage>? _stageSubscription;
  StreamSubscription<Map<String, dynamic>>? _statsSubscription;
  Timer? _secondsTimer;
  Timer? _chartUpdateTimer;

  @override
  VpnState build() {
    _initialize();
    ref.onDispose(() {
      _stageSubscription?.cancel();
      _statsSubscription?.cancel();
      _secondsTimer?.cancel();
      _chartUpdateTimer?.cancel();
    });
    return VpnState();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    state = state.copyWith(
      confPath: prefs.getString("confPath") ?? "",
      filename: prefs.getString("filename") ?? "",
      serverAddress: prefs.getString("serverAddress") ?? "",
    );

    await _vpnService.initializeVpn();

    _stageSubscription = _vpnService.vpnStageStream.listen((stage) {
      final now = DateTime.now();
      final newLog = "$now: Stage changed to $stage\n";

      bool isOn = state.isVPNOn;
      if (stage == VpnStage.connected) {
        isOn = true;
      } else if (stage == VpnStage.disconnecting ||
          stage == VpnStage.disconnected ||
          stage == VpnStage.denied ||
          stage == VpnStage.noConnection) {
        isOn = false;
      }

      state = state.copyWith(
        stage: stage,
        isVPNOn: isOn,
        logContent: state.logContent + newLog,
      );
    });

    _statsSubscription = _vpnService.trafficStatsSnapshot.listen((stats) {
      final currentIsOn = state.isVPNOn;

      _secondsTimer?.cancel();
      _secondsTimer = Timer(const Duration(seconds: 1), () {
        final currentTotalSeconds = state.totalSecondsConnected;
        state = state.copyWith(
          totalSecondsConnected: currentIsOn ? currentTotalSeconds + 1 : 0,
        );
      });

      final totalUpload = currentIsOn ? (stats['totalUpload'] ?? 0).toDouble() : 0;
      final totalDownload = currentIsOn ? (stats['totalDownload'] ?? 0).toDouble() : 0;
      final uploadSpeed = currentIsOn ? (stats['uploadSpeed'] ?? 0).toDouble() : 0;
      final downloadSpeed = currentIsOn ? (stats['downloadSpeed'] ?? 0).toDouble() : 0;

      state = state.copyWith(
        totalUpload: totalUpload,
        totalDownload: totalDownload,
        uploadSpeed: uploadSpeed,
        downloadSpeed: downloadSpeed,
      );

      if (!state.canUpdateChart) return;

      state = state.copyWith(canUpdateChart: false);

      final newTickCount = state.tickCount + 3;
      final newSentSpots = List<FlSpot>.from(state.sentSpots)
        ..add(FlSpot(newTickCount.toDouble(), totalUpload));
      final newReceivedSpots = List<FlSpot>.from(state.receivedSpots)
        ..add(FlSpot(newTickCount.toDouble(), totalDownload));

      if (newSentSpots.length > 15) {
        newSentSpots.removeAt(0);
        newReceivedSpots.removeAt(0);
      }

      double newMaxXSent = state.maxXSent;
      double newMaxXReceived = state.maxXReceived;
      if (newTickCount > 10) {
        newMaxXSent = newTickCount.toDouble();
        newMaxXReceived = newTickCount.toDouble();
      }

      double newMaxYSent = state.maxYSent;
      double newMaxYReceived = state.maxYReceived;
      if (totalUpload > state.maxYSent) {
        newMaxYSent = totalUpload * 1.2;
        newMaxYReceived = totalDownload * 1.2;
      }

      state = state.copyWith(
        tickCount: newTickCount,
        sentSpots: newSentSpots,
        receivedSpots: newReceivedSpots,
        maxXSent: newMaxXSent,
        maxXReceived: newMaxXReceived,
        maxYSent: newMaxYSent,
        maxYReceived: newMaxYReceived,
      );

      _chartUpdateTimer?.cancel();
      _chartUpdateTimer = Timer(const Duration(seconds: 3), () {
        state = state.copyWith(canUpdateChart: true);
      });
    });
  }

  Future<void> connectVpn() async {
    if (state.confPath.isNotEmpty) {
      final file = File(state.confPath);
      final fileContent = await file.readAsString();
      await _vpnService.connectVpn(state.serverAddress, fileContent);
    }
  }

  Future<void> disconnectVpn() async {
    await _vpnService.disconnectVpn();
  }

  Future<void> pickAndLoadFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [".conf"],
    );

    if (result != null) {
      final file = result.files.single;
      if (file.extension == "conf" || file.path!.endsWith('.conf')) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("confPath", file.path!);
        await prefs.setString("filename", file.name);

        state = state.copyWith(
          confPath: file.path!,
          filename: file.name,
        );
      }
    }
  }

  Future<void> updateServerAddress(String value) async {
    state = state.copyWith(serverAddress: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("serverAddress", value);
    await prefs.setString("filename", state.filename);
  }

  Future<void> openBrowser() async {
    final Uri url = Uri.parse('https://www.bbc.com/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }
}

final vpnProvider = NotifierProvider<VpnNotifier, VpnState>(VpnNotifier.new);