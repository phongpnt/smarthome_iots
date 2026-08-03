import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:flutter/material.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/widgets/Ktext.dart';

class SwitchSchedule extends StatelessWidget {
  const SwitchSchedule({this.onChangeStatus, this.value = false, Key? key})
      : super(key: key);

  final bool value;
  final Future<void> Function(bool value)? onChangeStatus;

  @override
  Widget build(BuildContext context) {
    return AnimatedToggleSwitch<bool>.dual(
      current: value,
      first: false,
      second: true,
      spacing: 10.0,
      height: 22,
      indicatorSize: Size(30, 20),
      style: ToggleStyle(
        borderColor: Colors.transparent,
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            spreadRadius: 1,
            blurRadius: 2,
            offset: Offset(0, .5),
          ),
        ],
      ),
      onChanged: (b) => onChangeStatus?.call(b),
      styleBuilder: (b) => ToggleStyle(
        indicatorColor: b ? AppColors.primaryColor : Colors.grey.shade400,
      ),
      iconBuilder: (value) => value
          ? Icon(Icons.power_settings_new_rounded, size: 16, color: Colors.white)
          : Icon(Icons.power_off_outlined, size: 16, color: Colors.white),
      textBuilder: (value) => value
          ? Center(
              child: KText(
                text: 'ON',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            )
          : Center(
              child: KText(
                  text: 'OFF',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
    );
  }
}
