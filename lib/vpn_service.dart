import 'package:wireguard_flutter_plus/wireguard_flutter_plus.dart';
import 'dart:io';

class VpnService {
  final _wireguardPlugin = WireGuardFlutter.instance;
  
  final String _tunnelName = "wg4k";

  Future<void> initializeVpn() async {
    await _wireguardPlugin.initialize(interfaceName: _tunnelName);
  }

  Future<void> connectVpn(String serverAddress, String confFileContent) async {
    if(serverAddress.isEmpty || confFileContent.isEmpty) return;

    await _wireguardPlugin.startVpn(
      serverAddress: serverAddress,
      wgQuickConfig: confFileContent, 
      providerBundleIdentifier: "com.example.vpn4k"
    );
  }

  Future<void> disconnectVpn() async {
    await _wireguardPlugin.stopVpn();
  }

  Stream<VpnStage> get vpnStageStream {
    return _wireguardPlugin.vpnStageSnapshot;
  }

  Stream<Map<String, dynamic>> get trafficStatsSnapshot {
    return _wireguardPlugin.trafficSnapshot;
  }
}


Future<bool> isWireGuardConnected() async {
  try {
    List<NetworkInterface> interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.any,
    );

    return interfaces.any((interface) {
      final name = interface.name.toLowerCase();
      return name.contains('wg') || name.contains('tun');
    });
  } catch (e) {
    return false;
  }
}