import 'dart:io';

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