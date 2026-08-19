import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:vpn4k/providers/vpn_provider.dart';

class OptionsTab extends ConsumerStatefulWidget {
  const OptionsTab({super.key});

  @override
  ConsumerState<OptionsTab> createState() => _OptionsTabState();
}

class _OptionsTabState extends ConsumerState<OptionsTab> {
  late final TextEditingController _controllerServerAddress;

  @override
  void initState() {
    super.initState();
    _controllerServerAddress = TextEditingController();
  }

  @override
  void dispose() {
    _controllerServerAddress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vpnState = ref.watch(vpnProvider);
    final vpnNotifier = ref.read(vpnProvider.notifier);

    if (_controllerServerAddress.text != vpnState.serverAddress) {
      _controllerServerAddress.text = vpnState.serverAddress;
    }

    final availableHeight = MediaQuery.sizeOf(context).height;
    final orientation = MediaQuery.of(context).orientation;

    const Color primaryColor = Colors.white;
    const Color secondaryColor = Color(0xFFB8B8B8);
    const Color indicatorColor = Color(0xFF99BCB7);
    const Color buttonActiveColor = Color(0xFF5A595C);

    return SingleChildScrollView(
      child: Container(
        height: orientation == Orientation.portrait ? availableHeight * 0.6 : availableHeight,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Configure", style: TextStyle(color: indicatorColor)),
                  const SizedBox(height: 5),
                  const Text("Enter server address", style: TextStyle(color: secondaryColor)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _controllerServerAddress,
                    maxLines: 1,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                      fillColor: Colors.transparent,
                      hintText: 'server address',
                    ),
                    onChanged: (value) => vpnNotifier.updateServerAddress(value),
                    onSubmitted: (value) => vpnNotifier.updateServerAddress(value),
                    onTapUpOutside: (event) => vpnNotifier.updateServerAddress(_controllerServerAddress.text),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "The client uses WireGuard\nSelect .conf file to use VPN",
                    style: TextStyle(color: secondaryColor),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width / 3,
                        child: TextButton(
                          onPressed: () => vpnNotifier.pickAndLoadFile(),
                          style: TextButton.styleFrom(
                            backgroundColor: buttonActiveColor,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          ),
                          child: const Text("Import File", style: TextStyle(color: primaryColor)),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        vpnState.filename.isEmpty ? "none selected" : vpnState.filename,
                        style: const TextStyle(color: secondaryColor),
                      )
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: primaryColor),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Information", style: TextStyle(color: indicatorColor)),
                  SizedBox(height: 5),
                  Text(
                    "Powered by 4aika_M\nThis is VPN client based on WireGuard.",
                    style: TextStyle(color: secondaryColor),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}