import 'package:get/get.dart';
import 'package:smart_home_app/src/repository/iaccount_responsitory.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';
import 'package:smart_home_app/src/service/local_storage.dart';
import 'package:smart_home_app/src/widgets/text_field/custom_text_field_model.dart';
import 'package:smart_home_app/src/widgets/text_field/text_form_model.dart';

class SignInController extends GetxController {
  final IAccountResponsitory accountResponsitory;
  final LocalStorage localStorage;
  final loading = false.obs;

  SignInController({
    required this.accountResponsitory,
    required this.localStorage,
  });

  late final CustomTextFieldModel email;
  late final CustomTextFieldModel password;
  late final TextFormModel textFormModel;

  @override
  void onInit() {
    super.onInit();
    email = CustomTextFieldModel(
      isRequired: true,
      validate: GetUtils.isEmail,
      errorValidateText: 'Email không hợp lệ',
    );
    password = CustomTextFieldModel(
      isRequired: true,
      validate: (value) => value.length >= 6,
      errorValidateText: 'Mật khẩu không hợp lệ',
    );
    textFormModel =
        TextFormModel(models: [email, password], onSubmit: onSubmit);
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void onSubmit() async {
    try {
      loading.value = true;
      final result = await accountResponsitory.login(
          email: email.text, pass: password.text);
      if (result.isNotEmpty) {
        await localStorage.cacheToken(result);
        await localStorage.cacheEmail(email.text);
        Get.offAllNamed(RouteName.HOME);
      }
    } catch (e) {
      email.errorText = 'Email hoặc mật khẩu không đúng. Vui lòng thử lại!';
      print(e);
    }

    loading.value = false;
  }
}
