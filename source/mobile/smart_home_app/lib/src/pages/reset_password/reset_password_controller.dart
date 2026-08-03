import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/reset_password/reset_password_argument.dart';
import 'package:smart_home_app/src/repository/iaccount_responsitory.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';
import 'package:smart_home_app/src/widgets/text_field/custom_text_field_model.dart';
import 'package:smart_home_app/src/widgets/text_field/text_form_model.dart';

class ResetPasswordController extends GetxController {
  final IAccountResponsitory accountResponsitory;
  final ResetPasswordArgument resetPasswordArgument;
  final loading = false.obs;

  ResetPasswordController(
      {required this.accountResponsitory, required this.resetPasswordArgument});

  late final CustomTextFieldModel password;
  late final CustomTextFieldModel confirmPassword;
  late final TextFormModel textFormModel;

  @override
  void onInit() {
    super.onInit();

    password = CustomTextFieldModel(
      isRequired: true,
      validate: (value) => value.length >= 6,
      errorValidateText: 'Mật khẩu không hợp lệ',
    );
    confirmPassword = CustomTextFieldModel(
      isRequired: true,
      validate: (value) => value.length >= 6 && value == password.text,
      errorValidateText: 'Mật khẩu xác nhận không khớp',
    );
    textFormModel =
        TextFormModel(models: [password, confirmPassword], onSubmit: onSubmit);
  }

  @override
  void dispose() {
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  void onSubmit() async {
    loading.value = true;
    try {
      await accountResponsitory.resetPassword(resetPasswordArgument.email,
          password.text, resetPasswordArgument.otp);
      Get.until((route) => Get.currentRoute == RouteName.SIGN_IN);
    } catch (e) {}
    loading.value = false;
  }
}
