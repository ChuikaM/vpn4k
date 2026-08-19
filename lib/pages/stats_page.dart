import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/vpn_provider.dart';
import '../../../utils/time_converter.dart';

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpnState = ref.watch(vpnProvider);
    final availableHeight = MediaQuery.sizeOf(context).height;
    final orientation = MediaQuery.of(context).orientation;

    const Color primaryColor = Colors.white;
    const Color secondaryColor = Color(0xFFB8B8B8);
    const Color chartLineColor = Color(0xFF606151);

    return SingleChildScrollView(
      child: Container(
        height: orientation == Orientation.portrait ? availableHeight * 0.6 : availableHeight,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
              child: Text(
                vpnState.isVPNOn ? "Connected: ${formatSecondsToTime(vpnState.totalSecondsConnected)}" : "Disconnected",
                style: const TextStyle(color: secondaryColor),
              ),
            ),
            Divider(color: primaryColor),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              child: Column(
                children: [
                  _buildStatRow("Total upload", "${vpnState.totalUpload.toStringAsFixed(0)} KiB", secondaryColor),
                  _buildStatRow("Upload speed", "${vpnState.uploadSpeed.toStringAsFixed(0)} B/s", secondaryColor),
                  _buildChart(vpnState.sentSpots, vpnState.maxXSent, vpnState.maxYSent, chartLineColor),
                  _buildStatRow("Total download", "${vpnState.totalDownload.toStringAsFixed(0)} KiB", secondaryColor),
                  _buildStatRow("Download speed", "${vpnState.downloadSpeed.toStringAsFixed(0)} B/s", secondaryColor),
                  _buildChart(vpnState.receivedSpots, vpnState.maxXReceived, vpnState.maxYReceived, chartLineColor),
                ],
              ),
            ),
            const Spacer()
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: color)),
        const Spacer(),
        Text(value, style: TextStyle(color: color)),
      ],
    );
  }

  Widget _buildChart(List<FlSpot> spots, double maxX, double maxY, Color lineColor) {
    return SizedBox(
      height: 100,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => const FlLine(color: Colors.grey, strokeWidth: 1),
            getDrawingVerticalLine: (value) => const FlLine(color: Colors.grey, strokeWidth: 1),
          ),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: spots.first.x,
          maxX: maxX,
          minY: 0,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: lineColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}