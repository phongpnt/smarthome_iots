import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/base/base_home_page.dart';
import 'package:smart_home_app/src/config/date_time_ext.dart';
import 'package:smart_home_app/src/config/image_path.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/model/data/power_usage.dart';
import 'package:smart_home_app/src/model/data/warning.dart';
import 'package:smart_home_app/src/pages/power_usage/power_usage_controller.dart';
import 'package:smart_home_app/src/repository/ipower_usage_repository.dart';
import 'package:smart_home_app/src/widgets/Ktext.dart';
import 'package:smart_home_app/src/widgets/grap.dart';
import 'package:smart_home_app/src/widgets/image_asset_view.dart';
import 'package:smart_home_app/src/widgets/light_usage_item.dart';
import 'package:smart_home_app/src/widgets/warning_ai_card.dart';

class PowerUsagePage extends BaseHomePage<PowerUsageController> {
  @override
  Widget buildAppbar(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: setPadding(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: KText(
                    text: 'Tiêu thụ điện',
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
                GestureDetector(
                  onTap: () => showFilterDialog(context),
                  child: Container(
                    padding: setPadding(all: 8.0),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50)),
                    child: ImageAssetView(
                      path: ImagePaths.persent,
                      color: AppColors.persentColor,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: height(8)),
          Obx(() => Padding(
            padding: setPadding(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: controller.prevPeriod,
                  child: Container(
                    padding: setPadding(all: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.periodLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: controller.isCurrentPeriod
                      ? null
                      : controller.nextPeriod,
                  child: Container(
                    padding: setPadding(all: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                          alpha: controller.isCurrentPeriod ? 0.05 : 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.chevron_right,
                        color: Colors.white.withValues(
                            alpha: controller.isCurrentPeriod ? 0.3 : 1.0),
                        size: 20),
                  ),
                ),
              ],
            ),
          )),
          SizedBox(height: height(8)),
          Obx(
            () => SizedBox(
              height: 200,
              width: Get.width,
              child: controller.chartData.value == null
                  ? const Center(child: CircularProgressIndicator())
                  : controller.chartData.value!.isEmpty
                      ? Center(
                          child: Text(
                            'Không có dữ liệu kỳ này',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13),
                          ),
                        )
                      : LineChartPowerUsage(
                          charts: controller.chartData.value!,
                          filter: controller.chartFilter.value,
                        ),
            ),
          )
        ],
      ),
    );
  }

  void showFilterDialog(BuildContext context) async {
    final result = await showDialog<ChartFilter>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: Get.width * .5,
          padding: setPadding(all: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...ChartFilter.values.map((e) => Padding(
                  padding: setPadding(bottom: 6),
                  child: GestureDetector(
                    onTap: () => Get.back(result: e),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            e.filterName,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        if (e == controller.chartFilter.value) ...[
                          Icon(Icons.check_circle, color: Colors.green)
                        ]
                      ],
                    ),
                  )))
            ],
          ),
        ),
      ),
    );

    if (result != null) {
      controller.onChangeFilter(result);
    }
  }

  @override
  Widget buildBody(BuildContext context) {
    return Obx(() {
      final length = controller.warningList.value
              ?.where((val) => (val.newIcon ?? false) == true)
              .length ??
          0;
      return Column(
        children: [
          TabBar(
            controller: controller.tabController,
            tabs: [
              const Tab(text: 'Tiêu thụ điện'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Cảnh báo'),
                    if (length > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$length',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: [
                Obx(() => _buildPowerUsage(
                    controller.filteredUsages.value?.cast<PowerUsage>())),
                _buildWarningList(controller.warningList.value)
              ],
            ),
          )
        ],
      );
    });
  }

  Widget _buildPowerUsage(List<PowerUsage>? usages) {
    if (usages == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: controller.onRefresh,
      child: Padding(
        padding: setPadding(top: 12),
        child: Obx(() {
          final hasMore = controller.hasMore;
          final itemCount = usages.length + 1;
          return ListView.separated(
            padding: setPadding(horizontal: 15, vertical: 20),
            itemCount: itemCount,
            shrinkWrap: true,
            physics: const BouncingScrollPhysics(),
            primary: false,
            separatorBuilder: (_, __) => SizedBox(height: height(12)),
            itemBuilder: (context, index) {
              if (index == usages.length) {
                if (!hasMore) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Center(
                      child: Text(
                        'Đã hiển thị tất cả ${usages.length} bản ghi',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: controller.loadMore,
                      icon: const Icon(Icons.expand_more, size: 18),
                      label: Text(
                        'Tải thêm 50 bản ghi',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primaryColor),
                      ),
                    ),
                  ),
                );
              }
              return LightUsageItem(powerUsage: usages[index]);
            },
          );
        }),
      ),
    );
  }

  Widget _buildWarningList(List<Warning>? warning) {
    if (warning == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (warning.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
            SizedBox(height: 12),
            Text('Không có cảnh báo nào',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: controller.onGetWarningList,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: warning.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              if ((warning[index].newIcon ?? false) == true) {
                controller.updateWarning(index, warning[index]);
              }
            },
            child: WarningAiCard(warning: warning[index]),
          );
        },
      ),
    );
  }
}
