import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_home_app/src/config/app_utils.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/model/data/device.dart';
import 'package:smart_home_app/src/widgets/image_asset_view.dart';

class DeviceItemView extends StatelessWidget {
  const DeviceItemView({
    Key? key,
    required this.devices,
    required this.onChangeStatus,
    this.onTap,
  }) : super(key: key);

  final Devices devices;
  final Future<void> Function(bool value) onChangeStatus;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isOn = devices.powerStatus == true;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: setPadding(horizontal: 14, top: 14, bottom: 12),
        decoration: BoxDecoration(
          color: isOn ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isOn ? AppColors.primaryColor : const Color(0xFF1E40AF))
                  .withValues(alpha: isOn ? 0.25 : 0.07),
              blurRadius: isOn ? 20 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOn
                        ? Colors.white.withValues(alpha: 0.15)
                        : AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ImageAssetView(
                    path: (devices.type ?? DeviceType.other).deviceImage,
                    size: width(36),
                    color: isOn ? Colors.white : AppColors.primaryColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOn
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppColors.grey100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOn
                              ? AppColors.success
                              : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOn ? 'Bật' : 'Tắt',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isOn ? Colors.white : AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: height(12)),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        devices.deviceName ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isOn ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 10,
                            color: isOn
                                ? Colors.white.withValues(alpha: 0.65)
                                : AppColors.textHint,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              devices.location ?? '',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w400,
                                color: isOn
                                    ? Colors.white.withValues(alpha: 0.65)
                                    : AppColors.textHint,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if ((devices.description ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          devices.description ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: isOn
                                ? Colors.white.withValues(alpha: 0.55)
                                : AppColors.textHint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Transform.scale(
                  scale: 0.82,
                  alignment: Alignment.centerRight,
                  child: Switch(
                    value: isOn,
                    onChanged: onChangeStatus,
                    activeThumbColor: AppColors.primaryColor,
                    activeTrackColor: Colors.white,
                    inactiveThumbColor: AppColors.textHint,
                    inactiveTrackColor:
                        Colors.grey.shade200,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    trackOutlineColor:
                        WidgetStateProperty.all(Colors.transparent),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
