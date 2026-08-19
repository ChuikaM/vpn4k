import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/vpn_provider.dart';
import '../../../utils/ui_utils.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpnState = ref.watch(vpnProvider);
    final availableHeight = MediaQuery.sizeOf(context).height;
    final orientation = MediaQuery.of(context).orientation;

    const Color secondaryColor = Color(0xFFB8B8B8);

    return Center(
      child: SingleChildScrollView(
        child: Container(
          height: orientation == Orientation.portrait ? availableHeight * 0.6 : availableHeight,
          padding: const EdgeInsets.symmetric(vertical: 20),
          alignment: Alignment.center,
          child: Column(
            children: [
              const Spacer(),
              Column(
                spacing: availableHeight / 20,
                children: [
                  SvgPicture.asset(getIconPathByStage(vpnState.stage)!),
                  Text(
                    getTextStage(vpnState.stage)!,
                    style: const TextStyle(color: secondaryColor, fontSize: 12),
                  )
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}