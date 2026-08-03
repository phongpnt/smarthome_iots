import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_home_app/src/model/data/power_usage_chart.dart';
import 'package:smart_home_app/src/repository/ipower_usage_repository.dart';

class LineChartPowerUsage extends StatelessWidget {
  const LineChartPowerUsage(
      {Key? key, required this.filter, this.charts = const []})
      : super(key: key);

  final ChartFilter filter;
  final List<PowerUsaegChart> charts;

  @override
  Widget build(BuildContext context) {
    if (filter == ChartFilter.day) {
      return _BarChartDay(charts: charts);
    }
    return _LineChartContent(filter: filter, charts: charts);
  }
}

class _BarChartDay extends StatelessWidget {
  const _BarChartDay({required this.charts});
  final List<PowerUsaegChart> charts;

  double get _maxY {
    if (charts.isEmpty) return 10;
    final m = charts.map((c) => (c.data ?? 0).toDouble()).reduce(max);
    return m <= 0 ? 1 : m;
  }

  String _label(int i) {
    if (i < 0 || i >= charts.length) return '';
    final date = charts[i].groupDataKeyEnd ?? '';
    final parts = date.split('-');
    return parts.length >= 2 ? '${parts[0]}/${parts[1]}' : date;
  }

  @override
  Widget build(BuildContext context) {
    final maxY = _maxY;
    final barWidth = charts.length <= 6 ? 24.0 : charts.length <= 12 ? 16.0 : 10.0;

    return Padding(
      padding: const EdgeInsets.only(right: 16, left: 6, top: 28, bottom: 10),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.35,
          minY: 0,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) => FlLine(
              color: Colors.white.withValues(alpha: 0.15),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3), width: 1),
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                interval: maxY / 4,
                getTitlesWidget: (v, _) => Text(
                  v < 1 ? v.toStringAsFixed(1) : v.toInt().toString(),
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 10),
                  textAlign: TextAlign.right,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    _label(v.round()),
                    style: const TextStyle(color: Colors.white70, fontSize: 9),
                  ),
                ),
              ),
            ),
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (v, meta) {
                  final i = v.round();
                  if (i < 0 || i >= charts.length) return const SizedBox.shrink();
                  final val = (charts[i].data ?? 0).toDouble();
                  if (val <= 0) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    space: 2,
                    child: Text(
                      val.toStringAsFixed(1),
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.black.withValues(alpha: 0.7),
              getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                '${_label(group.x)}\n',
                const TextStyle(color: Colors.white70, fontSize: 11),
                children: [
                  TextSpan(
                    text: '${rod.toY.toStringAsFixed(1)} Wh',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  )
                ],
              ),
            ),
          ),
          barGroups: charts.asMap().entries.map((e) {
            final val = (e.value.data ?? 0).toDouble();
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: val,
                  width: barWidth,
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY * 1.35,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        swapAnimationDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}

class _LineChartContent extends StatefulWidget {
  const _LineChartContent({required this.filter, required this.charts});
  final ChartFilter filter;
  final List<PowerUsaegChart> charts;

  @override
  State<_LineChartContent> createState() => _LineChartContentState();
}

class _LineChartContentState extends State<_LineChartContent> {
  static const int _windowSize = 7;

  late double _viewStart;
  int? _touchedIndex;

  @override
  void initState() {
    super.initState();
    _resetView();
  }

  @override
  void didUpdateWidget(covariant _LineChartContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.charts.length != widget.charts.length) {
      _resetView();
    }
  }

  void _resetView() {
    final total = widget.charts.length;
    _viewStart = max(0, total - _windowSize).toDouble();
  }

  double get _viewEnd => _viewStart + _windowSize;

  double get _maxY {
    if (widget.charts.isEmpty) return 100;
    return widget.charts.map((c) => (c.data ?? 0).toDouble()).reduce(max);
  }

  List<FlSpot> get _spots => widget.charts
      .asMap()
      .entries
      .map((e) => FlSpot(e.key.toDouble(), (e.value.data ?? 0).toDouble()))
      .toList();

  String _labelFor(int index) {
    if (index < 0 || index >= widget.charts.length) return '';
    final date = widget.charts[index].groupDataKeyEnd ?? '';
    final parts = date.split('-');
    if (parts.length >= 2) return '${parts[0]}/${parts[1]}';
    return date;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, left: 6, top: 10, bottom: 10),
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            final total = widget.charts.length.toDouble();
            final delta = -details.primaryDelta! / 12.0;
            _viewStart = (_viewStart + delta)
                .clamp(0.0, max(0.0, total - _windowSize));
          });
        },
        onDoubleTap: _resetView,
        child: LineChart(
          LineChartData(
            minX: _viewStart,
            maxX: _viewEnd,
            minY: 0,
            maxY: _maxY + _maxY * 0.15,
            clipData: FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _maxY > 0 ? _maxY / 4 : 25,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.white.withValues(alpha: 0.15),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.3), width: 1),
              ),
            ),
            lineTouchData: LineTouchData(
              touchCallback: (event, response) {
                setState(() {
                  _touchedIndex =
                      response?.lineBarSpots?.first.spotIndex;
                });
              },
              getTouchedSpotIndicator: (_, spots) => spots
                  .map((_) => TouchedSpotIndicatorData(
                        FlLine(
                            color: Colors.white.withValues(alpha: 0.5),
                            strokeWidth: 1,
                            dashArray: [4, 4]),
                        FlDotData(
                          getDotPainter: (_, __, ___, ____) =>
                              FlDotCirclePainter(
                            radius: 5,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.amber,
                          ),
                        ),
                      ))
                  .toList(),
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) =>
                    Colors.black.withValues(alpha: 0.7),
                getTooltipItems: (spots) => spots
                    .map((s) => LineTooltipItem(
                          '${_labelFor(s.spotIndex)}\n',
                          const TextStyle(
                              color: Colors.white70, fontSize: 11),
                          children: [
                            TextSpan(
                              text: '${s.y.toStringAsFixed(1)} Wh',
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                            )
                          ],
                        ))
                    .toList(),
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 46,
                  interval: _maxY > 0 ? _maxY / 4 : 25,
                  getTitlesWidget: (value, meta) => Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final i = value.round();
                    if (value != i.toDouble()) return const SizedBox.shrink();
                    final label = _labelFor(i);
                    if (label.isEmpty) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      space: 8,
                      child: Text(label,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 10)),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: _spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: Colors.white,
                barWidth: 2,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, _, __, index) =>
                      FlDotCirclePainter(
                    radius: index == _touchedIndex ? 5 : 3,
                    color: index == _touchedIndex
                        ? Colors.amber
                        : Colors.white,
                    strokeWidth: 1.5,
                    strokeColor: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
