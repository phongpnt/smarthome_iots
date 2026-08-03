import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/base/base_home_page.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/pages/upsert_schedule/upsert_schedule_controller.dart';
import 'package:smart_home_app/src/widgets/primary_button.dart';
import 'package:smart_home_app/src/widgets/switch_schedule.dart';

class UpsertSchedulePage extends BaseHomePage<UpsertScheduleController> {
  @override
  Widget buildAppbar(BuildContext context) => SafeArea(
        child: Container(
          padding: setPadding(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              GestureDetector(
                  onTap: () => Get.back(),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 24, color: AppColors.white)),
              SizedBox(width: width(12)),
              Expanded(
                  child: Text(
                controller.arguments?.schedule != null
                    ? "Cập nhật lịch"
                    : "Thêm lịch",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white),
              ))
            ],
          ),
        ),
      );

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        Expanded(
            child: Obx(
          () => ListView(
            padding: setPadding(horizontal: 12, vertical: 4),
            physics: BouncingScrollPhysics(),
            children: [
              Text('Ngày trong tuần',
                  style:
                      TextStyle(fontSize: 16, color: AppColors.primaryColor)),
              SizedBox(height: height(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final newIndex = index + 1;
                  final isContain =
                      controller.dayOfWeek.value.contains(newIndex.toString());
                  return GestureDetector(
                    onTap: () => controller.onUpsertDayOfWeek('$newIndex'),
                    child: Container(
                      padding: setPadding(all: 8),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isContain ? AppColors.dartkgrey : AppColors.white,
                          border: Border.all(color: AppColors.black)),
                      child: Text(
                        getDayOfWeek('$newIndex'),
                        style: TextStyle(
                            fontSize: 11,
                            color: isContain ? AppColors.white : null),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: height(8)),
              Padding(
                padding: setPadding(top: 12),
                child: GestureDetector(
                  onTap: () async {
                    final result = await showTimePicker(
                        context: context, initialTime: controller.time.value);
                    if (result != null) {
                      controller.time.value = result;
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Thời gian',
                            style: TextStyle(
                                fontSize: 16, color: AppColors.primaryColor)),
                      ),
                      SizedBox(width: width(8)),
                      Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border(bottom: BorderSide())),
                            child: Text(controller.timeText,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 17)),
                          ))
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              Text('Mô tả',
                  style:
                      TextStyle(fontSize: 16, color: AppColors.primaryColor)),
              SizedBox(height: 12),
              TextField(
                controller: controller.descriptionCtrl,
                maxLines: null,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.black))),
              ),
              SizedBox(height: 12),
              _buildLineDropDown<Devices>(
                'Thiết bị',
                controller.deviceService.devices.value ?? <Devices>[],
                controller.currentDevice,
                getData: (p0) => p0.deviceName ?? '',
                onSelectData: (p0) =>
                    controller.device.value = p0.deviceId ?? '',
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Kích hoạt',
                      style: TextStyle(
                          fontSize: 16, color: AppColors.primaryColor)),
                  SwitchSchedule(
                    onChangeStatus: (value) async =>
                        controller.active.value = value,
                    value: controller.active.value,
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Trạng thái',
                      style: TextStyle(
                          fontSize: 16, color: AppColors.primaryColor)),
                  SwitchSchedule(
                    onChangeStatus: (value) async =>
                        controller.powerStatus.value = value,
                    value: controller.powerStatus.value,
                  ),
                ],
              ),
            ],
          ),
        )),
        SizedBox(height: height(12)),
        Obx(
          () => SafeArea(
            top: false,
            child: Padding(
              padding: setPadding(horizontal: 12),
              child: PrimaryButton(
                isLoading: controller.isLoading.value,
                onTap: controller.arguments?.schedule != null
                    ? controller.onUpdateSchedule
                    : controller.onAddSchedule,
                buttonText: controller.arguments?.schedule != null
                    ? 'Cập nhật'
                    : 'Thêm mới',
              ),
            ),
          ),
        )
      ],
    );
  }

  String getDayOfWeek(String text) {
    switch (text) {
      case '1':
        return 'T2';
      case '2':
        return 'T3';
      case '3':
        return 'T4';
      case '4':
        return 'T5';
      case '5':
        return 'T6';
      case '6':
        return 'T7';
      case '7':
        return 'CN';
    }

    return 'T2';
  }

  Widget _buildLineDropDown<T>(String text, List<T> items, T? value,
      {required String Function(T) getData,
      required Function(T) onSelectData}) {
    return Padding(
      padding: setPadding(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 16, color: AppColors.primaryColor)),
          ),
          SizedBox(width: width(8)),
          Expanded(
              flex: 2,
              child: DropdownButton<T>(
                  value: value,
                  isExpanded: true,
                  items: items
                      .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            getData(e),
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(fontSize: 14, color: AppColors.black),
                          )))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      onSelectData(value);
                    }
                  }))
        ],
      ),
    );
  }
}
