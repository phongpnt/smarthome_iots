import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/base/base_home_page.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/pages/change_password/change_password_controller.dart';
import 'package:smart_home_app/src/widgets/primary_button.dart';
import 'package:smart_home_app/src/widgets/text_field/custom_text_field.dart';

class ChangePasswordPage extends BaseHomePage<ChangePasswordController> {
  @override
  Widget buildAppbar(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Icon(Icons.arrow_back_ios_outlined,
                size: 24, color: AppColors.white),
          ),
          SizedBox(width: 12),
          Text('Đổi mật khẩu',
              style: TextStyle(
                fontSize: 24,
                color: AppColors.white,
              )),
        ],
      ),
    );
  }

  @override
  Widget buildBody(BuildContext context) {
    return Padding(
      padding: setPadding(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 12),
          CustomTextField(
            isPassword: true,
            model: controller.oldPassword,
            hint: 'Mật khẩu hiện tại',
          ),
          SizedBox(height: 12),
          CustomTextField(
            isPassword: true,
            model: controller.password,
            hint: 'Mật khẩu mới',
          ),
          SizedBox(height: 12),
          CustomTextField(
            model: controller.confirmPassword,
            isPassword: true,
            hint: 'Xác nhận mật khẩu mới',
          ),
          SizedBox(height: 12),
          Obx(
            () => PrimaryButton(
              buttonText: 'Xác nhận',
              isLoading: controller.loading.value,
              onTap: controller.textFormModel.validate,
            ),
          ),
        ],
      ),
    );
  }
}
