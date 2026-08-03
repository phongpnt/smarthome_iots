import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_home_app/src/base/base_login_page.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/pages/sign_up/sign_up_controller.dart';
import 'package:smart_home_app/src/widgets/primary_button.dart';
import 'package:smart_home_app/src/widgets/text_field/custom_text_field.dart';

class SignUpPage extends BaseLoginPage<SignUpController> {
  @override
  Widget buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: Get.back,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.primaryColor),
              ),
            ),
            SizedBox(width: width(12)),
            Text(
              'Tạo tài khoản',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 44),
          child: Text(
            'Điền thông tin để đăng ký',
            style: GoogleFonts.inter(
                fontSize: 13, color: AppColors.textHint),
          ),
        ),
        const SizedBox(height: 20),

        _Label('Họ và tên'),
        const SizedBox(height: 6),
        CustomTextField(
          model: controller.fullname,
          hint: 'Nguyễn Văn A',
        ),
        const SizedBox(height: 14),

        _Label('Email'),
        const SizedBox(height: 6),
        CustomTextField(
          obscureText: false,
          model: controller.email,
          hint: 'example@gmail.com',
        ),
        const SizedBox(height: 14),

        _Label('Mật khẩu'),
        const SizedBox(height: 6),
        CustomTextField(
          model: controller.password,
          isPassword: true,
          hint: '••••••••',
        ),
        const SizedBox(height: 14),

        _Label('Xác nhận mật khẩu'),
        const SizedBox(height: 6),
        CustomTextField(
          model: controller.confirmPassword,
          isPassword: true,
          hint: '••••••••',
        ),
        const SizedBox(height: 20),

        Obx(
          () => PrimaryButton(
            buttonText: 'Đăng ký',
            isLoading: controller.loading.value,
            onTap: controller.textFormModel.validate,
          ),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary),
    );
  }
}
