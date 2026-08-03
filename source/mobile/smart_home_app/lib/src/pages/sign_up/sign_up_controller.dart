import 'package:get/get.dart';
import 'package:smart_home_app/src/repository/iaccount_responsitory.dart';
import 'package:smart_home_app/src/service/local_storage.dart';
import 'package:smart_home_app/src/widgets/text_field/custom_text_field_model.dart';
import 'package:smart_home_app/src/widgets/text_field/text_form_model.dart';

class SignUpController extends GetxController {
  final IAccountResponsitory accountResponsitory;
  final LocalStorage localStorage;
  final loading = false.obs;

  SignUpController({
    required this.accountResponsitory,
    required this.localStorage,
  });

  late final CustomTextFieldModel email;
  late final CustomTextFieldModel password;
  late final CustomTextFieldModel fullname;
  late final CustomTextFieldModel confirmPassword;
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
    fullname = CustomTextFieldModel(
      isRequired: true,
      validate: (value) => value.length >= 6,
      errorValidateText: 'Họ tên không hợp lệ',
    );
    confirmPassword = CustomTextFieldModel(
      isRequired: true,
      validate: (value) => value.length >= 6 && value == password.text,
      errorValidateText: 'Mật khẩu xác nhận không khớp',
    );
    textFormModel = TextFormModel(
        models: [email, password, fullname, confirmPassword],
        onSubmit: onSubmit);
  }

  @override
  void dispose() {
    textFormModel.dispose();
    super.dispose();
  }

  void onSubmit() async {
    try {
      loading.value = true;
      await accountResponsitory.register(
          fullname.text, email.text, password.text);
      Get.back();
    } catch (e) {
      print(e);
    }

    loading.value = false;
  }
}
