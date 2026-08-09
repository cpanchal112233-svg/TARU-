import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/measurement_chart_points.dart';

/// Compact raw line chart for measurement history (supplementary to the list).
///
/// Points are actual recordings only — no synthetic dates, smoothing, or
/// clinical bands.
class RawMeasurementChart extends StatelessWidget {
  const RawMeasurementChart({
    super.key,
    required this.series,
    this.semanticsLabel = 'Recent measurement chart',
    this.height = 180,
  });

  /// One or more series already ordered oldest → newest.
  final List<RawChartSeries> series;
  final String semanticsLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final List<RawChartSeries> drawable = series
        .where((RawChartSeries s) => s.points.isNotEmpty)
        .toList();
    if (drawable.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<MeasurementChartPoint> allPoints = drawable
        .expand((RawChartSeries s) => s.points)
        .toList();
    final double minX = allPoints
        .map((MeasurementChartPoint p) => _x(p.recordedAt))
        .reduce((double a, double b) => a < b ? a : b);
    final double maxX = allPoints
        .map((MeasurementChartPoint p) => _x(p.recordedAt))
        .reduce((double a, double b) => a > b ? a : b);
    final double minY = allPoints
        .map((MeasurementChartPoint p) => p.value)
        .reduce((double a, double b) => a < b ? a : b);
    final double maxY = allPoints
        .map((MeasurementChartPoint p) => p.value)
        .reduce((double a, double b) => a > b ? a : b);

    final double xPad = maxX == minX ? 1 : (maxX - minX) * 0.05;
    final double yPad = maxY == minY ? (maxY.abs() * 0.05 + 1) : (maxY - minY) * 0.12;

    return Semantics(
      label: semanticsLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (drawable.any((RawChartSeries s) => s.label != null)) ...[
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                for (final RawChartSeries s in drawable)
                  if (s.label != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: s.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          s.label!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            height: height,
            width: double.infinity,
            child: LineChart(
              LineChartData(
                minX: minX - xPad,
                maxX: maxX + xPad,
                minY: minY - yPad,
                maxY: maxY + yPad,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: _niceInterval(minY - yPad, maxY + yPad),
                  getDrawingHorizontalLine: (double value) => FlLine(
                    color: Colors.grey.shade200,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: Colors.grey.shade300),
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        return Text(
                          _formatAxis(value),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: maxX == minX ? 1 : (maxX - minX) / 2,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final DateTime at = DateTime.fromMillisecondsSinceEpoch(
                          value.round(),
                        ).toLocal();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '${at.day}/${at.month}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  for (final RawChartSeries s in drawable)
                    LineChartBarData(
                      spots: [
                        for (final MeasurementChartPoint p in s.points)
                          FlSpot(_x(p.recordedAt), p.value),
                      ],
                      isCurved: false,
                      color: s.color,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter:
                            (FlSpot spot, double xPercentage, LineChartBarData bar, int index) {
                          return FlDotCirclePainter(
                            radius: 3.2,
                            color: s.color,
                            strokeWidth: 0,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(show: false),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static double _x(DateTime recordedAt) =>
      recordedAt.millisecondsSinceEpoch.toDouble();

  static double _niceInterval(double min, double max) {
    final double span = (max - min).abs();
    if (span <= 0) return 1;
    return span / 3;
  }

  static String _formatAxis(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
}

@immutable
class RawChartSeries {
  const RawChartSeries({
    required this.points,
    required this.color,
    this.label,
  });

  final List<MeasurementChartPoint> points;
  final Color color;
  final String? label;
}
