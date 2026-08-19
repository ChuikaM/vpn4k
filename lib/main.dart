import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/vpn_provider.dart';
import 'pages/home_page.dart';
import 'pages/stats_page.dart';
import 'pages/options_page.dart';
import 'pages/logs_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpnState = ref.watch(vpnProvider);
    final vpnNotifier = ref.read(vpnProvider.notifier);

    final availableHeight = MediaQuery.sizeOf(context).height;

    const Color backgroundAppColor = Color(0xFF303030);
    const Color backgroundTitleColor = Color(0xFF212121);
    const Color indicatorColor = Color(0xFF99BCB7);
    const Color primaryColor = Colors.white;
    const Color secondaryColor = Color(0xFFB8B8B8);
    
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
              title: const Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("VPN4k", style: TextStyle(color: primaryColor, fontSize: 12)),
                  Text("v 0.1.0", style: TextStyle(color: primaryColor, fontSize: 12))
                ],
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
            body: const TabBarView(
              children: [
                HomeTab(),
                StatsTab(),
                OptionsTab(),
                LogsTab(),
              ],
            ),
            bottomNavigationBar: BottomAppBar(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
              height: MediaQuery.orientationOf(context) == Orientation.portrait
                  ? availableHeight / 18
                  : availableHeight / 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        if (vpnState.isVPNOn) {
                          vpnNotifier.disconnectVpn();
                        } else {
                          vpnNotifier.connectVpn();
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: buttonActiveColor,
                        minimumSize: const Size.fromHeight(double.infinity),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text(
                        vpnState.isVPNOn ? "Stop" : "Start",
                        style: const TextStyle(color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: vpnState.isVPNOn ? () => vpnNotifier.openBrowser() : null,
                      style: TextButton.styleFrom(
                        backgroundColor: vpnState.isVPNOn ? buttonActiveColor : buttonInactiveColor,
                        minimumSize: const Size.fromHeight(double.infinity),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      ),
                      child: Text(
                        "Open Browser",
                        style: TextStyle(color: vpnState.isVPNOn ? primaryColor : textInactiveColor),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}