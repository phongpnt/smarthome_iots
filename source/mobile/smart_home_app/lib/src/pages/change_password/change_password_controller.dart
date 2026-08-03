import 'package:get/get.dart';
import 'package:smart_home_app/src/repository/iaccount_responsitory.dart';
import 'package:smart_home_app/src/service/account_service.dart';
import 'package:smart_home_app/src/widgets/flash/toast.dart';
import 'package:smart_home_app/src/widgets/text_field/custom_text_field_model.dart';
import 'package:smart_home_app/src/widgets/text_field/text_form_model.dart';

class ChangePasswordController extends GetxController {
  final IAccountResponsitory accountResponsitory;
  final AccountService accountService;
  final loading = false.obs;

  ChangePasswordController(
      {required this.accountResponsitory, required this.accountService});

  late final CustomTextFieldModel oldPassword;
  late final CustomTextFieldModel password;
  late final CustomTextFieldModel confirmPassword;
  late final TextFormModel textFormModel;

  @override
  void onInit() {
    super.onInit();

    oldPassword = CustomTextFieldModel(
      isRequired: true,
      validate: (value) =>
          value.length >= 6 && value == accountService.account?.passKey,
      errorValidateText: 'Mật khẩu không hợp lệ',
    );
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
    textFormModel = TextFormModel(
        models: [oldPassword, password, confirmPassword], onSubmit: onSubmit);
  }

  @override
  void dispose() {
    oldPassword.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  void onSubmit() async {
    loading.value = true;
    try {
      final newAccount =
          accountService.account!.copyWith(passKey: password.text);
      await accountResponsitory.updateAccount(newAccount);
      accountService.setAccount(newAccount);
      showToast('Đổi mật khẩu thành công');
    } catch (e) {}
    loading.value = false;
  }
}
