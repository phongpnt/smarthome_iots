import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/model/data/account.dart';
import 'package:smart_home_app/src/model/data/power_usage.dart';
import 'package:smart_home_app/src/pages/main/main_controller.dart';
import 'package:smart_home_app/src/model/data/power_usage_chart.dart';
import 'package:smart_home_app/src/model/data/warning.dart';

import 'package:smart_home_app/src/repository/idevice_repository.dart';
import 'package:smart_home_app/src/repository/ipower_usage_repository.dart';
import 'package:smart_home_app/src/service/account_service.dart';
import 'package:smart_home_app/src/service/device_service.dart';

class PowerUsageController extends GetxController
    with GetSingleTickerProviderStateMixin {
  final IDeviceResponsitory deviceResponsitory;
  final IPowerUsageRepository powerUsageRepository;
  final DeviceService deviceService;
  final AccountService accountService;

  final chartData      = Rx<List<PowerUsaegChart>?>(null);
  final chartFilter    = Rx<ChartFilter>(ChartFilter.week);
  final periodOffset   = 0.obs;  // 0 = kỳ hiện tại, -1 = kỳ trước, ...
  final warningList    = Rx<List<Warning>?>(null);
  final filteredUsages = Rx<List<dynamic>?>(null);
  final isChartLoading = false.obs;
  final isLoadingMore  = false.obs;

  static const _pageSize = 50;
  int _displayPage = 1;  // số trang đang hiển thị (mỗi trang 50 record)

  bool get hasMore {
    final all = _cache[_cacheKey()];
    if (all == null) return false;
    return _displayPage * _pageSize < all.length;
  }

  late final TabController tabController =
      TabController(length: 2, vsync: this);

  final _cache = <String, List<PowerUsage>>{};

  PowerUsageController({
    required this.deviceResponsitory,
    required this.deviceService,
    required this.powerUsageRepository,
    required this.accountService,
  });

  late final StreamSubscription<Account?> _sub;

  String get periodLabel {
    final (start, end) = _dateRangeFor(chartFilter.value, periodOffset.value);
    switch (chartFilter.value) {
      case ChartFilter.day:
        return _fmt(start);
      case ChartFilter.week:
        final last = end.subtract(const Duration(days: 1));
        return '${_fmtShort(start)} – ${_fmt(last)}';
      case ChartFilter.month:
        return '${_monthName(start.month)} ${start.year}';
    }
  }

  bool get isCurrentPeriod => periodOffset.value == 0;

  @override
  void onInit() {
    super.onInit();
    _sub = accountService.accountStream.listen((event) {
      if (event != null) {
        _sub.cancel();
        _fetchAndBuildChart();
      }
    });
    if (accountService.account != null) {
      _fetchAndBuildChart();
    }
    onGetWarningList();
  }

  @override
  void onClose() {
    warningList.close();
    tabController.dispose();
    super.onClose();
  }

  void prevPeriod() {
    _displayPage = 1;
    periodOffset.value--;
    _fetchAndBuildChart();
  }

  void nextPeriod() {
    if (periodOffset.value < 0) {
      _displayPage = 1;
      periodOffset.value++;
      _fetchAndBuildChart();
    }
  }

  void onChangeFilter(ChartFilter filter) {
    chartFilter.value = filter;
    periodOffset.value = 0;
    _displayPage = 1;
    _fetchAndBuildChart();
  }

  void loadMore() {
    final all = _cache[_cacheKey()];
    if (all == null || !hasMore) return;
    _displayPage++;
    filteredUsages.value = all.take(_displayPage * _pageSize).toList();
  }

  Future<void> onRefresh() async {
    _displayPage = 1;
    _cache.remove(_cacheKey());
    await _fetchAndBuildChart();
  }

  String _cacheKey() =>
      '${chartFilter.value.name}_${periodOffset.value}';

  Future<void> _fetchAndBuildChart() async {
    final userId = accountService.account?.userId;
    if (userId == null) return;

    final key = _cacheKey();

    if (_cache.containsKey(key)) {
      _buildChartFromList(_cache[key]!);
      return;
    }

    isChartLoading.value = true;
    chartData.value = null;
    filteredUsages.value = null;

    final (start, end) = _dateRangeFor(chartFilter.value, periodOffset.value);
    final raw = await deviceResponsitory.getPowerUsageByRange(userId, start, end);

    final devices = deviceService.devices.value ?? [];
    final joined = raw.map((u) {
      final idx = devices.indexWhere((d) => d.deviceId == u.deviceId);
      return idx != -1 ? u.copyWith(devices: devices[idx]) : u;
    }).toList();

    _cache[key] = joined;
    isChartLoading.value = false;
    _buildChartFromList(joined);
  }

  void _buildChartFromList(List<PowerUsage> list) {
    filteredUsages.value = list.take(_displayPage * _pageSize).toList();

    final Map<String, double> grouped = {};
    for (final u in list) {
      final dt = DateTime.tryParse(u.calculateDate ?? '');
      if (dt == null) continue;
      final key =
          '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
      grouped[key] = (grouped[key] ?? 0.0) + (u.powerUsageWat ?? 0.0);
    }

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => _parseKey(a).compareTo(_parseKey(b)));

    chartData.value = sortedKeys
        .map((k) => PowerUsaegChart(
              groupDataKeyStart: k,
              groupDataKeyEnd: k,
              data: grouped[k],
            ))
        .toList();
  }

  (DateTime, DateTime) _dateRangeFor(ChartFilter filter, int offset) {
    final now = DateTime.now();
    switch (filter) {
      case ChartFilter.day:
        final day = DateTime(now.year, now.month, now.day)
            .add(Duration(days: offset));
        return (day, day.add(const Duration(days: 1)));

      case ChartFilter.week:
        final todayMon = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final start = todayMon.add(Duration(days: 7 * offset));
        return (start, start.add(const Duration(days: 7)));

      case ChartFilter.month:
        final start = DateTime(now.year, now.month + offset, 1);
        final end   = DateTime(start.year, start.month + 1, 1);
        return (start, end);
    }
  }

  DateTime _parseKey(String key) {
    final p = key.split('-');
    if (p.length < 3) return DateTime(0);
    return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  String _monthName(int m) => const [
        '', 'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
        'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
        'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
      ][m];

  Future<void> onGetWarningList() async {
    warningList.value = null;
    final result = await powerUsageRepository.getListWarning();
    result.sort((a, b) {
      final unreadA = a.newIcon == true ? 1 : 0;
      final unreadB = b.newIcon == true ? 1 : 0;
      if (unreadA != unreadB) return unreadB - unreadA;  // unread lên trước
      final da = DateTime.tryParse(a.createdDate ?? '') ?? DateTime(0);
      final db = DateTime.tryParse(b.createdDate ?? '') ?? DateTime(0);
      return db.compareTo(da);  // mới nhất lên trên
    });
    warningList.value = result;
    try {
      final count = result.where((w) => w.newIcon == true).length ?? 0;
      Get.find<MainController>().unreadWarnings.value = count;
    } catch (_) {}
  }

  Future<void> updateWarning(int index, Warning warning) async {
    final list = [...warningList.value!];
    final newWarning = warning.copyWith(newIcon: false);
    list[index] = newWarning;
    warningList.value = [...list];
    _syncBadge(list);
    try {
      await powerUsageRepository.updateWarning(newWarning);
    } catch (_) {}
  }

  void _syncBadge(List<Warning> list) {
    try {
      final count = list.where((w) => w.newIcon == true).length;
      Get.find<MainController>().unreadWarnings.value = count;
    } catch (_) {}
  }
}
