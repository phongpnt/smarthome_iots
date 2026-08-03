import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/base/base_home_page.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/pages/smart_home/smart_home_controller.dart';
import 'package:smart_home_app/src/pages/main/main_controller.dart';
import 'package:smart_home_app/src/pages/power_usage/power_usage_controller.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';
import 'package:smart_home_app/src/widgets/Ktext.dart';
import 'package:smart_home_app/src/widgets/ai_schedule_sheet.dart';
import 'package:smart_home_app/src/widgets/schedule_item.dart';

class SmartHomePage extends BaseHomePage<SmartHomeController> {
  @override
  Color get bodyBackground => AppColors.lightgrey;

  @override
  Color get backgroundColor => AppColors.lightgrey;

  @override
  Widget buildAppbar(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: height(40)),
        Padding(
          padding: setPadding(horizontal: 15, bottom: 15),
          child: Row(
            children: [
              Expanded(
                child: KText(
                  text: 'Smart Home',
                  color: Colors.white,
                  fontSize: 22,
                ),
              ),
              GestureDetector(
                onTap: () {
                  try { Get.find<MainController>().onChangePage(2); } catch (_) {}
                  Future.delayed(const Duration(milliseconds: 300), () {
                    try { Get.find<PowerUsageController>().tabController.animateTo(1); } catch (_) {}
                  });
                },
                child: Obx(() {
                  final count = () {
                    try { return Get.find<MainController>().unreadWarnings.value; } catch (_) { return 0; }
                  }();
                  return Stack(clipBehavior: Clip.none, children: [
                    Container(
                      height: 35, width: 35,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50)),
                      child: const Icon(Icons.notifications, color: Colors.black54),
                    ),
                    if (count > 0)
                      Positioned(
                        top: -4, right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: Text(count > 99 ? '99+' : '$count',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ]);
                }),
              )
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Obx(() {
      final schedules = controller.deviceService.schedules.value;
      return ListView(
        padding: setPadding(horizontal: 15),
        children: [
          SizedBox(height: height(10)),
          Row(
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
                  text: '${schedules?.length ?? 0}',
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: () => Get.bottomSheet(
                  const AiScheduleSheet(),
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                ),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.primaryColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.auto_awesome,
                          size: 15, color: AppColors.primaryColor),
                      SizedBox(width: 4),
                      Text('AI gợi ý',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                  onTap: () => Get.toNamed(RouteName.UPSERT_SCHEDULE),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                  )),
            ],
          ),
          if (schedules == null)
            Center(child: CircularProgressIndicator())
          else
            ListView.separated(
                physics: BouncingScrollPhysics(),
                itemCount: schedules.length,
                padding: setPadding(top: 12),
                shrinkWrap: true,
                primary: false,
                separatorBuilder: (context, index) =>
                    SizedBox(height: height(10)),
                itemBuilder: (BuildContext context, int index) =>
                    ScheduleItemView(
                      schedule: schedules[index],
                      onChangeStatus: (value) => controller.deviceService
                          .onUpdatePowerStatusSchedule(index, value),
                      onDelete: () => controller.onDeleteSchedule(index),
                    )),
        ],
      );
    });
  }
}
