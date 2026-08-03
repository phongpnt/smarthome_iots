import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/verify_otp/verify_otp_argument.dart';
import 'package:smart_home_app/src/repository/iaccount_responsitory.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';
import 'package:smart_home_app/src/widgets/text_field/custom_text_field_model.dart';

class ForgotPasswordController extends GetxController {
  final IAccountResponsitory accountResponsitory;
  late final CustomTextFieldModel email;
  final loading = false.obs;
  ForgotPasswordController({required this.accountResponsitory});

  @override
  void onInit() {
    super.onInit();
    email = CustomTextFieldModel(
        isRequired: true,
        validate: GetUtils.isEmail,
        errorValidateText: 'Email không hợp lệ');
  }

  void onSubmit() async {
    if (email.onValidate() == false) {
      return;
    }
    loading.value = true;
    try {
      await accountResponsitory.forgotPassword(email.text);
      Get.toNamed(RouteName.VERIFY_OTP,
          arguments: VerifyOTPArgument(email: email.text));
    } catch (e) {
      print(e);
      email.errorText = 'Email không tồn tại hoặc không đúng';
    }
    loading.value = false;
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }
}
