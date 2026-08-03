import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/base/base_home_page.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/pages/upsert_device/upsert_device_controller.dart';
import 'package:smart_home_app/src/widgets/image_asset_view.dart';
import 'package:smart_home_app/src/widgets/primary_button.dart';
import 'package:smart_home_app/src/widgets/switch_schedule.dart';

class UpsertDevicePage extends BaseHomePage<UpsertDeviceController> {
  @override
  Widget buildAppbar(BuildContext context) => SafeArea(
        child: Container(
          padding: setPadding(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              GestureDetector(
                  onTap: Get.back,
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      size: 24, color: AppColors.white)),
              SizedBox(width: width(12)),
              Expanded(
                  child: Text(
                controller.arguments?.devices != null
                    ? "Cập nhật thiết bị"
                    : "Thêm thiết bị",
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
              _buildColText("Tên thiết bị", controller.deviceName),
              _buildColText("Vị trí", controller.location),
              _buildColText("Mô tả", controller.description),
              _buildColText("Tên WiFi", controller.ssid),
              _buildColText("Mật khẩu WiFi", controller.passWifi),
              _buildColText(
                controller.arguments?.devices != null
                    ? "Device MAC (ID)"
                    : "Device MAC *",
                controller.deviceMac,
                readOnly: controller.arguments?.devices != null,
                hint: "VD: 64b708b78e24",
              ),
              _buildLineDropDown<DeviceType>(
                'Loại thiết bị',
                DeviceType.values,
                controller.type.value,
                getImage: (value) => value.deviceImage,
                getData: (p0) => p0.name,
                onSelectData: (p0) => controller.type.value = p0,
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
                        controller.devicePowerStatus.value = value,
                    value: controller.devicePowerStatus.value,
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
                onTap: controller.arguments?.devices != null
                    ? controller.onUpdateDevice
                    : controller.onAddDevice,
                buttonText: controller.arguments?.devices != null
                    ? 'Cập nhật'
                    : 'Thêm mới',
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildLineDropDown<T>(String text, List<T> items, T? value,
      {required String Function(T) getImage,
      required String Function(T)? getData,
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ImageAssetView(path: getImage(e), size: 24),
                              SizedBox(width: width(4)),
                              Text(getData?.call(e) ?? '')
                            ],
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

  Widget _buildColText<T>(String text, TextEditingController controller,
      {bool readOnly = false, String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8),
        Text(text,
            style: TextStyle(fontSize: 16, color: AppColors.primaryColor)),
        SizedBox(height: 4),
        TextField(
          controller: controller,
          readOnly: readOnly,
          decoration: InputDecoration(
              hintText: hint,
              contentPadding: setPadding(vertical: 4, horizontal: 12),
              border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.black)),
              filled: readOnly,
              fillColor: readOnly ? Colors.grey.shade200 : null),
        ),
        SizedBox(height: 8),
      ],
    );
  }
}
