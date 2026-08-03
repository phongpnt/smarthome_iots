import 'package:flutter/material.dart';
import 'package:smart_home_app/src/config/app_utils.dart';
import 'package:smart_home_app/src/config/date_time_ext.dart';
import 'package:smart_home_app/src/config/image_path.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/model/data/power_usage.dart';
import 'package:smart_home_app/src/widgets/Ktext.dart';
import 'package:smart_home_app/src/widgets/image_asset_view.dart';
import 'package:smart_home_app/src/model/data/device.dart';

class LightUsageItem extends StatelessWidget {
  const LightUsageItem({
    Key? key,
    required this.powerUsage,
  }) : super(key: key);

  final PowerUsage powerUsage;

  @override
  Widget build(BuildContext context) {
    final day = powerUsage.calculateDate?.dd_MM_yyy ?? '';
    final start =
        powerUsage.startDate?.toDateTime().toLocal() ?? DateTime.now();
    final end = powerUsage.endDate?.toDateTime().toLocal() ?? DateTime.now();
    final duration = end.difference(start);
    return Container(
      padding: setPadding(all: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(height: height(8)),
          Container(
            margin: setPadding(right: 12),
            padding: setPadding(all: 10),
            decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(14)),
            child: ImageAssetView(
              path: powerUsage.devices?.type?.deviceImage ?? ImagePaths.light,
              width: 36,
              color: AppColors.primaryColor,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                KText(
                  text: powerUsage.devices?.deviceName ?? '',
                  fontSize: 14,
                ),
                KText(
                  text: powerUsage.devices?.location ?? '',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                KText(
                  text: day,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.blueGrey.withValues(alpha: 0.7),
                ),
                KText(
                  text: 'Sử dụng ${getDuration(duration)}',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.blueGrey.withValues(alpha: 0.7),
                )
              ],
            ),
          ),
          Container(
            margin: setPadding(right: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    KText(
                      text: (powerUsage.powerUsageWat ?? 0.0).toStringAsFixed(1),
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    KText(
                      text: ' Wh',
                      fontWeight: FontWeight.w400,
                      color: AppColors.textHint,
                      fontSize: 12,
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  String getDuration(Duration duration) {
    final totalMinutes = duration.inMinutes.abs();
    final hours   = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${getTime(hours)}:${getTime(minutes)}';
  }
}
