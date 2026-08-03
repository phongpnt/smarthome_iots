import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/base/base_home_page.dart';
import 'package:smart_home_app/src/config/image_path.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/model/data/power_usage_chart.dart';
import 'package:smart_home_app/src/pages/detail/details_controller.dart';
import 'package:smart_home_app/src/pages/upsert_device/upsert_device_argument.dart';
import 'package:smart_home_app/src/pages/upsert_schedule/upsert_schedule_parameter.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';
import 'package:smart_home_app/src/widgets/Ktext.dart';
import 'package:smart_home_app/src/widgets/image_asset_view.dart';
import 'package:smart_home_app/src/widgets/schedule_item.dart';

class DetailsPage extends BaseHomePage<DetailsController> {
  @override
  double? get topRadius => 0;

  @override
  Color get bodyBackground => AppColors.lightgrey;

  @override
  Widget buildAppbar(BuildContext context) {
    return Padding(
      padding: setPadding(horizontal: 15, bottom: 5),
      child: Column(
        children: [
          _buildAppbarTitle(),
          _buildAppbarBody(),
        ],
      ),
    );
  }

  Widget _buildAppbarTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Obx(() {
          final isOn = controller.devices.value.powerStatus == true;
          return SafeArea(
            bottom: false,
            left: false,
            right: false,
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: Get.back,
                      child: Row(
                        children: [
                          Padding(
                            padding: setPadding(top: 8),
                            child: Icon(
                              Icons.arrow_back_ios,
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                          Padding(
                            padding: setPadding(top: 8),
                            child: KText(
                              text: 'Quay lại',
                              color: Colors.white,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: setPadding(top: 8),
                      child: KText(
                        text: controller.devices.value.location ?? '',
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    Padding(
                      padding: setPadding(top: 5),
                      child: GestureDetector(
                        onTap: () =>
                            controller.onUpdatePowerStatusDevice(!isOn),
                        child: ImageAssetView(
                            path: isOn ? ImagePaths.onIcon : ImagePaths.offIcon,
                            width: isOn ? 48 : 24,
                            height: isOn ? 48 : 24),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                Image.asset(
                    controller.devices.value.type?.deviceImage ?? ImagePaths.tv,
                    width: 48,
                    height: 48)
              ],
            ),
          );
        }),
        GestureDetector(
            onTap: () async {
              final result = await Get.toNamed(RouteName.UPSERT_DEVICE,
                  arguments:
                      UpsertDeviceArgument(devices: controller.devices.value));
              if (result != null) {
                controller.devices.value = result;
              }
            },
            child: Icon(Icons.edit, size: 26, color: AppColors.white))
      ],
    );
  }

  Widget _buildAppbarBody() {
    return Obx(() {
      final today = controller.today.value ?? <PowerUsaegChart>[];
      final week = controller.week.value ?? <PowerUsaegChart>[];
      final month = controller.month.value ?? <PowerUsaegChart>[];

      return Column(
        children: [
          SizedBox(height: height(10)),
          Divider(color: Colors.white60),
          SizedBox(height: height(10)),
          Row(
            children: [
              KText(
                text: 'Tiêu thụ',
                fontSize: 16,
                color: Colors.white,
              ),
            ],
          ),
          _buildLineText('Hôm nay', '${getPowerUsageFromList(today)} W/h'),
          _buildLineText('Tuần này', '${getPowerUsageFromList(week)} W/h'),
          _buildLineText('Tháng này', '${getPowerUsageFromList(month)} W/h'),
        ],
      );
    });
  }

  String getPowerUsageFromList(List<PowerUsaegChart> usages) {
    if (usages.isEmpty) return '0.0';
    final total = usages.fold<double>(0.0, (sum, e) => sum + (e.data ?? 0.0));
    return total.toStringAsFixed(1);
  }

  _buildLineText(String text, String value) {
    return Row(
      children: [
        Expanded(
          child: KText(
            text: text,
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.w300,
          ),
        ),
        KText(
          text: value,
          fontSize: 16,
          color: Colors.white,
        ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
          padding: setPadding(horizontal: 15, bottom: 20),
          child: Column(
            children: [
              SizedBox(height: height(5)),
              Row(
                children: [
                  Expanded(
                      child: Row(
                    children: [
                      KText(
                        text: 'Lịch hẹn',
                        fontSize: 17,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            borderRadius: BorderRadius.circular(20)),
                        child: KText(
                          text: '${controller.schedules.value?.length ?? 0}',
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )),
                  GestureDetector(
                      onTap: () async {
                        final result = await Get.toNamed(
                            RouteName.UPSERT_SCHEDULE,
                            arguments: UpsertScheduleParameter(
                                devices: controller.devices.value));
                        if (result != null) {
                          controller.onAddSchedule(result);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_rounded, size: 22, color: Colors.white),
                      )),
                ],
              ),
              if (controller.schedules.value == null)
                Center(child: CircularProgressIndicator())
              else
                ListView.separated(
                  padding: setPadding(top: 4),
                  physics: BouncingScrollPhysics(),
                  itemCount: controller.schedules.value!.length,
                  shrinkWrap: true,
                  primary: false,
                  separatorBuilder: (context, index) =>
                      SizedBox(height: height(8)),
                  itemBuilder: (BuildContext context, int index) {
                    return ScheduleItemView(
                      onUpdateDevice: controller.onUpdateSchedule,
                      schedule: controller.schedules.value![index],
                      onChangeStatus: (value) =>
                          controller.onUpdatePowerStatusSchedule(index, value),
                      onDelete: () => controller.onDeleteSchedule(index),
                    );
                  },
                )
            ],
          )),
    );
  }
}
