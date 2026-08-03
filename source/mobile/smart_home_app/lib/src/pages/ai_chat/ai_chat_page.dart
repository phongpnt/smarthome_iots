import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/pages/ai_chat/ai_chat_controller.dart';
import 'package:smart_home_app/src/service/ai_service.dart';

class AiChatPage extends GetView<AiChatController> {
  const AiChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildQuickChips(),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
        backgroundColor: AppColors.primaryColor,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trợ lý AI',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Obx(() => Text(
                      controller.isLoading.value ? 'Đang phân tích...' : 'AI Nhà thông minh',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                    )),
              ],
            ),
          ],
        ),
      );

  Widget _buildMessageList() => Obx(() => ListView.builder(
        controller: controller.scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: controller.messages.length +
            (controller.isLoading.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.messages.length) {
            return _buildTypingIndicator();
          }
          return _buildMessageBubble(controller.messages[index]);
        },
      ));

  Widget _buildMessageBubble(AiMessage msg) {
    final isUser = msg.isUser;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? AppColors.primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : const Color(0xFF2F4858),
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(msg.time),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildAvatar() => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
      );

  Widget _buildTypingIndicator() => Padding(
        padding: const EdgeInsets.only(bottom: 10, right: 48),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                  bottomLeft: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (i) => _DotAnimation(delay: i * 200),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildQuickChips() => SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: AiChatController.quickQuestions.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, i) {
            final q = AiChatController.quickQuestions[i];
            return GestureDetector(
              onTap: () => controller.sendMessage(q),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  q,
                  style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500),
                ),
              ),
            );
          },
        ),
      );

  Widget _buildInputBar() => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7F9),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: controller.inputCtrl,
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: controller.sendMessage,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Hỏi AI về thiết bị của bạn...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Obx(() => GestureDetector(
                    onTap: () =>
                        controller.sendMessage(controller.inputCtrl.text),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: controller.isLoading.value
                            ? Colors.grey.shade300
                            : AppColors.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        controller.isLoading.value
                            ? Icons.hourglass_empty
                            : Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  )),
            ],
          ),
        ),
      );

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _DotAnimation extends StatefulWidget {
  final int delay;
  const _DotAnimation({required this.delay});

  @override
  State<_DotAnimation> createState() => _DotAnimationState();
}

class _DotAnimationState extends State<_DotAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.primaryColor
                .withValues(alpha: 0.3 + 0.7 * _anim.value),
            shape: BoxShape.circle,
          ),
        ),
      );
}
