import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/base/base_login_page.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/pages/forgot_password/forgot_password_controller.dart';
import 'package:smart_home_app/src/widgets/primary_button.dart';
import 'package:smart_home_app/src/widgets/text_field/custom_text_field.dart';

class ForgotPasswordPage extends BaseLoginPage<ForgotPasswordController> {
  @override
  Widget buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
              onTap: Get.back,
              child: Icon(Icons.arrow_back_ios_outlined,
                  size: 24, color: AppColors.primaryColor),
            ),
            Text('Quên mật khẩu',
                style: TextStyle(
                    fontSize: 24,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 8),
        Text('Chúng tôi sẽ gửi mã xác nhận đến email của bạn.',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textColorGrey,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        CustomTextField(
          model: controller.email,
          hint: 'Nhập email',
        ),
        SizedBox(height: 8),
        Obx(
          () => PrimaryButton(
            buttonText: 'Tiếp theo',
            isLoading: controller.loading.value,
            onTap: controller.onSubmit,
          ),
        )
      ],
    );
  }
}
