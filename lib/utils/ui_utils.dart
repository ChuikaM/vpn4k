import 'package:wireguard_flutter_plus/wireguard_flutter_platform_interface.dart';

String? getIconPathByStage(VpnStage stage) {
  const String pathIconInactive = "assets/icon_inactive.svg";
  const String pathIconActive = "assets/icon_active.svg";
  const String pathIconInProgress = "assets/icon_in_progress.svg";

  const Map<VpnStage, String> stageIcons = {
    VpnStage.disconnecting: pathIconInactive,
    VpnStage.disconnected: pathIconInactive,
    VpnStage.preparing: pathIconInProgress,
    VpnStage.connecting: pathIconInProgress,
    VpnStage.connected: pathIconActive,
    VpnStage.denied: pathIconInactive,
    VpnStage.noConnection: pathIconInactive,
  };

  return stageIcons[stage] ?? pathIconInactive;
}

String? getTextStage(VpnStage stage) {
  const Map<VpnStage, String> stageTexts = {
    VpnStage.disconnecting: "Disconnecting...",
    VpnStage.disconnected: "Disconnected",
    VpnStage.preparing: "Connecting...",
    VpnStage.connecting: "Connecting...",
    VpnStage.connected: "Connected",
  };

  return stageTexts[stage];
}