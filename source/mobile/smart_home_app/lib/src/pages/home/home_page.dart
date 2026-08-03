import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/base/base_home_page.dart';
import 'package:smart_home_app/src/config/app_utils.dart';
import 'package:smart_home_app/src/config/image_path.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/pages/detail/detail_agurement.dart';
import 'package:smart_home_app/src/pages/home/home_controller.dart';
import 'package:smart_home_app/src/pages/home/widget/device_item_view.dart';
import 'package:smart_home_app/src/pages/upsert_device/upsert_device_argument.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';
import 'package:smart_home_app/src/widgets/Ktext.dart';
import 'package:smart_home_app/src/pages/main/main_controller.dart';
import 'package:smart_home_app/src/pages/power_usage/power_usage_controller.dart';
import 'package:smart_home_app/src/widgets/image_asset_view.dart';
import 'package:smart_home_app/src/widgets/list_vertical_item.dart';

class HomePage extends BaseHomePage<HomeController> {
  @override
  EdgeInsets get appBarPadding => const EdgeInsets.symmetric(vertical: 12);

  @override
  Widget buildAppbar(BuildContext context) {
    return Column(
      children: [
        _buildAppbarTitle(),
        _buildAppbarBody(),
      ],
    );
  }

  Widget _buildAppbarTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15, left: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KText(
                text: getHello(),
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              KText(text: getFullNameUser())
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            right: 15,
            top: 35,
            bottom: 20,
          ),
          child: GestureDetector(
            onTap: () {
              try {
                Get.find<MainController>().onChangePage(2);
              } catch (_) {}
              Future.delayed(const Duration(milliseconds: 300), () {
                try {
                  Get.find<PowerUsageController>().tabController.animateTo(1);
                } catch (_) {}
              });
            },
            child: Obx(() {
              final count = () {
                try {
                  return Get.find<MainController>().unreadWarnings.value;
                } catch (_) {
                  return 0;
                }
              }();
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(50)),
                    child: const Icon(
                      Icons.notifications,
                      color: Colors.black54,
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
        )
      ],
    );
  }

  Widget _buildAppbarBody() {
    return Obx(() {
      final w = controller.weather.value;
      final hasError = controller.weatherError.value.isNotEmpty;

      final tempText = w != null ? '${w.tempCelsius.round()}' : '--';
      final descText = w?.description ?? (hasError ? 'N/A' : '...');
      final locationText = w != null
          ? '${w.cityName}, ${w.country}'
          : (hasError ? 'Không lấy được vị trí' : 'Đang lấy vị trí...');
      final humidityText = w != null ? '${w.humidity}' : '--';
      final visibilityText =
          w != null ? w.visibility.toStringAsFixed(0) : '--';
      final windText =
          w != null ? w.windSpeed.toStringAsFixed(0) : '--';

      return Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 15, left: 12, right: 12),
                        child: ImageAssetView(
                            width: 60,
                            height: 60,
                            path: ImagePaths.sunBehindCloud),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 10, left: 3, right: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              KText(text: getDateTime(), fontSize: 12),
                              KText(text: descText, fontSize: 18),
                              KText(text: locationText, fontSize: 12),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Row(
                        children: [
                          KText(text: '$tempText$degree', fontSize: 42),
                          KText(text: 'c', fontSize: 42),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Divider(color: Colors.grey[500]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 5),
                    child: Row(
                      children: [
                        _buildStatusWeather(
                            ImagePaths.drop, humidityText, '%', 'Độ ẩm'),
                        const SizedBox(width: 8),
                        _buildStatusWeather(
                            ImagePaths.eye, visibilityText, 'km', 'Tầm nhìn'),
                        const SizedBox(width: 8),
                        _buildStatusWeather(
                            ImagePaths.sonofoll, windText, 'km/h', 'Gió'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          bottom: 0,
          right: 0,
          child: ImageAssetView(path: ImagePaths.sunTop),
        ),
      ],
    );
    });  // end Obx
  }

  Widget _buildStatusWeather(
      String imagePath, String value, String type, String text) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.lightgrey),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: ImageAssetView(
                        path: imagePath,
                        height: 15,
                        width: 15,
                      ),
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                          fontSize: 25),
                      children: [
                        TextSpan(
                          text: value,
                        ),
                        WidgetSpan(
                          child: Transform.translate(
                            offset: const Offset(0.0, 0.0),
                            child: Text(
                              type,
                              style: TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            KText(
              text: text,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: setPadding(left: 15, right: 15, top: 15, bottom: 5),
          child: Row(
            children: [
              Expanded(
                child: KText(
                  text: 'Thiết bị',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 36, height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('Thêm thiết bị',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary)),
                            const SizedBox(height: 16),
                            _AddOption(
                              icon: Icons.qr_code_scanner_rounded,
                              label: 'Quét mã QR',
                              onTap: () async {
                                Get.back();
                                final result = await Get.toNamed(RouteName.SCAN_QR);
                                if (result != null) {
                                  Get.toNamed(RouteName.UPSERT_DEVICE,
                                      arguments: UpsertDeviceArgument(id: result));
                                }
                              },
                            ),
                            const SizedBox(height: 10),
                            _AddOption(
                              icon: Icons.edit_outlined,
                              label: 'Nhập thông tin',
                              onTap: () {
                                Get.back();
                                Get.toNamed(RouteName.UPSERT_DEVICE);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
        ),
        Expanded(
          child: Padding(
            padding: setPadding(horizontal: 12),
            child: Obx(() {
              final devices = controller.deviceService.devices.value;
              if (devices == null) {
                return Center(child: CircularProgressIndicator());
              }
              return RefreshIndicator(
                onRefresh: controller.onRefresh,
                child: ListVerticalItem(
                  items: devices,
                  divider: SizedBox(height: 12),
                  itemBuilder: (index, Devices item) {
                    return DeviceItemView(
                      devices: item,
                      onChangeStatus: (value) => controller.deviceService
                          .onChangeStatus(index, value),
                      onTap: () => Get.toNamed(RouteName.DETAILS,
                          arguments: DetailsAgurement(devices: item)),
                    );
                  },
                ),
              );
            }),
          ),
        )
      ],
    );
  }
}

getDateTime() {
  DateTime now = DateTime.now();
  var currentTime =
      DateTime(now.year, now.month, now.day, now.hour, now.minute);
  return currentTime.toString();
}

class _AddOption extends StatelessWidget {
  const _AddOption({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primaryColor),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

getFullNameUser() {
  return "Phùng Nguyễn Thanh Phong";
}

getHello() {
  var str = 'Xin chào';
  DateTime now = DateTime.now();
  if (now.hour >= 6 && now.hour <= 12) {
    str = "Chào buổi sáng";
  } else if (now.hour > 12 && now.hour <= 18) {
    str = "Chào buổi chiều";
  } else {
    str = "Chào buổi tối";
  }
  return str;
}
