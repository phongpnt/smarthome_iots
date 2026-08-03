import 'package:get/get.dart';
import 'package:smart_home_app/src/pages/ai_chat/ai_chat_controller.dart';

class AiChatBinding implements Bindings {
  @override
  void dependencies() {
    Get.put(AiChatController(
      aiService: Get.find(),
      accountService: Get.find(),
    ));
  }
}
