import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/config/image_path.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/model/data/schedule.dart';
import 'package:smart_home_app/src/pages/upsert_schedule/upsert_schedule_parameter.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';
import 'package:smart_home_app/src/widgets/Ktext.dart';
import 'package:smart_home_app/src/widgets/image_asset_view.dart';
import 'package:smart_home_app/src/widgets/switch_schedule.dart';

class ScheduleItemView extends StatelessWidget {
  const ScheduleItemView({
    required this.schedule,
    required this.onChangeStatus,
    Key? key,
    this.onUpdateDevice,
    this.onDelete,
  }) : super(key: key);

  final Schedule schedule;
  final Future<void> Function(bool value) onChangeStatus;
  final Function(Schedule schedule)? onUpdateDevice;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Get.toNamed(RouteName.UPSERT_SCHEDULE,
            arguments: UpsertScheduleParameter(schedule: schedule));
        if (result != null) {
          onUpdateDevice?.call(result);
        }
      },
      child: Container(
        padding: setPadding(all: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: setPadding(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KText(
                          text: schedule.deviceName ??
                              schedule.devices?.deviceName ??
                              '',
                          fontSize: 15,
                        ),
                        KText(
                          text:
                              '${schedule.location ?? schedule.devices?.location ?? ''}  | ${schedule.dayText}',
                          fontWeight: FontWeight.w400,
                        ),
                      ],
                    ),
                  ),
                  SwitchSchedule(
                    onChangeStatus: onChangeStatus,
                    value: schedule.active ?? false,
                  ),
                ],
              ),
            ),
            Padding(
              padding: setPadding(horizontal: 8),
              child: Row(
                children: [
                  ImageAssetView(
                      path: schedule.type?.deviceImage ??
                          schedule.devices?.type?.deviceImage ??
                          ImagePaths.airConditioner,
                      height: 45),
                  SizedBox(width: width(5)),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        KText(
                          text: 'Time',
                          fontWeight: FontWeight.w400,
                        ),
                        KText(
                          text: schedule.time ?? '',
                          fontSize: 16,
                        )
                      ],
                    ),
                  ),
                  Container(
                    height: 40,
                    width: 1,
                    color: Colors.blueGrey,
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        KText(
                          text: (schedule.powerStatus ?? false) ? 'ON' : 'OFF',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: (schedule.powerStatus ?? false)
                              ? Colors.teal
                              : Colors.grey,
                        ),
                        SizedBox(height: height(6)),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (onDelete == null) return;
                            Get.dialog(AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text('Xóa lịch hẹn',
                                  style: TextStyle(fontSize: 16)),
                              content: const Text(
                                  'Bạn chắc chắn muốn xóa lịch hẹn này?',
                                  style: TextStyle(fontSize: 14)),
                              actions: [
                                TextButton(
                                    onPressed: Get.back,
                                    child: const Text('Hủy')),
                                TextButton(
                                    onPressed: () {
                                      Get.back();
                                      onDelete!();
                                    },
                                    child: const Text('Xóa',
                                        style: TextStyle(color: Colors.red))),
                              ],
                            ));
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: const [
                              ImageAssetView(path: ImagePaths.delete, height: 18),
                            ],
                          ),
                        ),
                        SizedBox(height: height(4)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            ImageAssetView(path: ImagePaths.edit, height: 18),
                          ],
                        ),
                      ],
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
