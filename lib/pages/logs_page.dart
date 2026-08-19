import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/vpn_provider.dart';

class LogsTab extends ConsumerStatefulWidget {
  const LogsTab({super.key});

  @override
  ConsumerState<LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends ConsumerState<LogsTab> {
  final ScrollController _logScrollController = ScrollController();

  @override
  void dispose() {
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vpnState = ref.watch(vpnProvider);
    const Color secondaryColor = Color(0xFFB8B8B8);

    return RawScrollbar(
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          child: Text(
            vpnState.logContent,
            style: const TextStyle(color: secondaryColor),
          ),
        ),
      ),
    );
  }
}