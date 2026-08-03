import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/service/account_service.dart';
import 'package:smart_home_app/src/service/ai_service.dart';

class AiChatController extends GetxController {
  final AiService aiService;
  final AccountService accountService;

  AiChatController({required this.aiService, required this.accountService});

  final messages = <AiMessage>[].obs;
  final isLoading = false.obs;
  final inputCtrl = TextEditingController();
  final scrollCtrl = ScrollController();

  static const List<String> quickQuestions = [
    'Tổng điện năng hôm nay?',
    'Dự báo tiền điện tháng này?',
    'Tiền điện tháng trước?',
    'So sánh tiền điện 3 tháng gần đây?',
    'So sánh tiền điện 6 tháng gần đây?',
    'So sánh tiền điện cùng kỳ năm ngoái?',
    'Thiết bị nào tốn điện nhất tuần này?',
    'Có cảnh báo bất thường không?',
    'Thiết bị nào đang bật?',
  ];

  @override
  void onInit() {
    super.onInit();
    messages.add(AiMessage(
      text: 'Xin chào! Tôi là AI trợ lý Smart Home. '
          'Hỏi tôi về điện năng, thiết bị, hoặc cảnh báo của bạn nhé.',
      isUser: false,
    ));
  }

  @override
  void onClose() {
    inputCtrl.dispose();
    scrollCtrl.dispose();
    super.onClose();
  }

  Future<void> sendMessage(String text) async {
    final q = text.trim();
    if (q.isEmpty || isLoading.value) return;

    inputCtrl.clear();
    messages.add(AiMessage(text: q, isUser: true));
    isLoading.value = true;
    _scrollToBottom();

    try {
      final userId = accountService.account?.userId ?? '';
      final answer = await aiService.query(q, userId);
      messages.add(AiMessage(text: answer, isUser: false));
    } catch (_) {
      messages.add(AiMessage(
        text: 'Tôi chưa thể trả lời lúc này. Vui lòng thử lại sau.',
        isUser: false,
      ));
    } finally {
      isLoading.value = false;
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollCtrl.hasClients) {
        scrollCtrl.animateTo(
          scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
