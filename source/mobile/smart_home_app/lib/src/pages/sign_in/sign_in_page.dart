import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_home_app/src/base/base_login_page.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/widgets/primary_button.dart';
import 'package:smart_home_app/src/pages/sign_in/sign_in_controller.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';
import 'package:smart_home_app/src/widgets/text_field/custom_text_field.dart';

class SignInPage extends BaseLoginPage<SignInController> {
  @override
  Widget buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Chào mừng',
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Đăng nhập để tiếp tục',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textHint,
          ),
        ),
        const SizedBox(height: 24),

        Text('Email',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        CustomTextField(
          model: controller.email,
          hint: 'example@gmail.com',
        ),
        const SizedBox(height: 16),

        Text('Mật khẩu',
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        CustomTextField(
          model: controller.password,
          isPassword: true,
          hint: '••••••••',
        ),
        const SizedBox(height: 8),

        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () => Get.toNamed(RouteName.FORGOT_PASSWORD),
            child: Text(
              'Quên mật khẩu?',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        Obx(
          () => PrimaryButton(
            buttonText: 'Đăng nhập',
            isLoading: controller.loading.value,
            onTap: controller.textFormModel.validate,
          ),
        ),
        const SizedBox(height: 20),

        Center(
          child: RichText(
            text: TextSpan(children: [
              TextSpan(
                text: 'Chưa có tài khoản? ',
                style: GoogleFonts.inter(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              TextSpan(
                text: 'Đăng ký',
                recognizer: TapGestureRecognizer()
                  ..onTap = () => Get.toNamed(RouteName.SIGN_UP),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
