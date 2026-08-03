import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/change_password/change_password_binding.dart';
import 'package:smart_home_app/src/pages/change_password/change_password_page.dart';
import 'package:smart_home_app/src/pages/detail/details_binding.dart';
import 'package:smart_home_app/src/pages/detail/details_page.dart';
import 'package:smart_home_app/src/pages/forgot_password/forgot_password_binding.dart';
import 'package:smart_home_app/src/pages/forgot_password/forgot_password_page.dart';
import 'package:smart_home_app/src/pages/main/main_binding.dart';
import 'package:smart_home_app/src/pages/main/main_page.dart';
import 'package:smart_home_app/src/pages/reset_password/reset_password_binding.dart';
import 'package:smart_home_app/src/pages/reset_password/reset_password_page.dart';
import 'package:smart_home_app/src/pages/scan_qr/scan_qr_binding.dart';
import 'package:smart_home_app/src/pages/scan_qr/scan_qr_page.dart';
import 'package:smart_home_app/src/pages/sign_in/sign_in_binding.dart';
import 'package:smart_home_app/src/pages/sign_in/sign_in_page.dart';
import 'package:smart_home_app/src/pages/sign_up/sign_up_binding.dart';
import 'package:smart_home_app/src/pages/sign_up/sign_up_page.dart';
import 'package:smart_home_app/src/pages/upsert_device/upsert_device_binding.dart';
import 'package:smart_home_app/src/pages/upsert_device/upsert_device_page.dart';
import 'package:smart_home_app/src/pages/upsert_schedule/upsert_schedule_binding.dart';
import 'package:smart_home_app/src/pages/upsert_schedule/upsert_schedule_page.dart';
import 'package:smart_home_app/src/pages/verify_otp/verify_otp_binding.dart';
import 'package:smart_home_app/src/pages/verify_otp/verify_otp_page.dart';
import 'package:smart_home_app/src/routes/middleware/authen_middleware.dart';
import 'package:smart_home_app/src/routes/middleware/sign_in_middleware.dart';
import 'package:smart_home_app/src/routes/route_constant.dart';

class AppRoute {
  static List<GetPage> pages = [
    GetPage(
      name: RouteName.SIGN_IN,
      page: () => SignInPage(),
      binding: SignInBinding(),
      middlewares: [SignInMiddleware()],
    ),
    GetPage(
      name: RouteName.SIGN_UP,
      page: () => SignUpPage(),
      binding: SignUpBinding(),
    ),
    GetPage(
      name: RouteName.FORGOT_PASSWORD,
      page: () => ForgotPasswordPage(),
      binding: ForgotPasswordBinding(),
    ),
    GetPage(
      name: RouteName.RESET_PASSWORD,
      page: () => ResetPasswordPage(),
      binding: ResetPasswordBinding(),
    ),
    GetPage(
      name: RouteName.VERIFY_OTP,
      page: () => VerifyOTPPage(),
      binding: VerifyOTPBinding(),
    ),
    GetPage(
        name: RouteName.HOME,
        page: () => MainPage(),
        binding: MainBinding(),
        middlewares: [AuthenMiddleware()]),
    GetPage(
        name: RouteName.DETAILS,
        page: () => DetailsPage(),
        binding: DetailsBinding(),
        middlewares: [AuthenMiddleware()]),
    GetPage(
        name: RouteName.UPSERT_SCHEDULE,
        page: () => UpsertSchedulePage(),
        binding: UpsertScheduleBinding(),
        middlewares: [AuthenMiddleware()]),
    GetPage(
        name: RouteName.UPSERT_DEVICE,
        page: () => UpsertDevicePage(),
        binding: UpsertDeviceBinding()),
    GetPage(
        name: RouteName.CHANGE_PASSWORD,
        page: () => ChangePasswordPage(),
        binding: ChangePasswordBinding()),
    GetPage(
        name: RouteName.SCAN_QR,
        page: () => ScanQRPage(),
        binding: ScanQRBinding())
  ];
}
