import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/base/base_login_page.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/pages/verify_otp/verify_otp_controller.dart';
import 'package:smart_home_app/src/widgets/horzontal_items_view.dart';
import 'package:smart_home_app/src/widgets/primary_button.dart';

class VerifyOTPPage extends BaseLoginPage<VerifyOTPController> {
  @override
  Widget buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 30),
        Row(
          children: [
            GestureDetector(
              onTap: Get.back,
              child: Icon(Icons.arrow_back_ios_outlined,
                  size: 24, color: AppColors.primaryColor),
            ),
            Text('Mã xác nhận',
                style: TextStyle(
                    fontSize: 24,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 8),
        Text('Nhập mã xác nhận chúng tôi vừa gửi đến email của bạn.',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textColorGrey,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Stack(
          children: [
            ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller.textCtrl,
                builder: (context, text, child) => HorizontalItemsView<String>(
                      size: 40,
                      paddingItem: 6,
                      items: List.generate(
                          controller.lengthOtp,
                          (index) =>
                              text.text.length > index ? text.text[index] : ''),
                      itemBuilder: (item, index) => Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Text(
                            item,
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    )),
            Opacity(
              opacity: 0,
              child: TextField(
                controller: controller.textCtrl,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(controller.lengthOtp)
                ],
                keyboardType: TextInputType.number,
              ),
            )
          ],
        ),
        Obx(() => controller.error.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  controller.error.value,
                  style: TextStyle(fontSize: 14, color: Colors.red),
                ),
              )
            : SizedBox()),
        SizedBox(height: 8),
        Obx(
          () => PrimaryButton(
            isLoading: controller.loading.value,
            buttonText: 'Xác nhận',
            onTap: controller.onSubmit,
          ),
        )
      ],
    );
  }
}
