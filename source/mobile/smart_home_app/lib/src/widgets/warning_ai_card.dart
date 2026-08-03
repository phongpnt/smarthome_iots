import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/model/data/warning.dart';
import 'package:smart_home_app/src/pages/ai_chat/ai_chat_controller.dart';
import 'package:smart_home_app/src/pages/main/main_controller.dart';

class WarningAiCard extends StatelessWidget {
  final Warning warning;

  const WarningAiCard({super.key, required this.warning});

  @override
  Widget build(BuildContext context) {
    if (warning.isMlAnomaly) return _MlAnomalyCard(warning: warning);
    if (warning.isProphet)   return _ProphetCard(warning: warning);
    return _RuleBasedCard(warning: warning);
  }
}

class _MlAnomalyCard extends StatelessWidget {
  final Warning warning;
  const _MlAnomalyCard({required this.warning});

  static const _purple     = Color(0xFF534AB7);
  static const _purpleDeep = Color(0xFF3C3489);
  static const _purpleBg   = Color(0xFFEEEDFE);
  static const _purpleBdr  = Color(0xFFAFA9EC);

  @override
  Widget build(BuildContext context) {
    final isUnread = warning.newIcon == true;
    final score    = warning.anomalyScore ?? 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isUnread ? _purpleBg.withValues(alpha: 0.4) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _purpleBdr,
          width: isUnread ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: isUnread ? 0.14 : 0.06),
            blurRadius: isUnread ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isUnread)
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: _purple,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _purpleBg,
                      borderRadius: BorderRadius.only(
                        topLeft:  Radius.circular(isUnread ? 0 : 11),
                        topRight: const Radius.circular(11),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.scatter_plot_rounded,
                            color: _purple, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            warning.warningTitle
                                    ?.replaceFirst(RegExp(r'^\[Isolation Forest\] |\[ML\] '), '') ??
                                'Bất thường hành vi',
                            style: const TextStyle(
                              color: _purpleDeep,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _purple,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.psychology_outlined,
                                  size: 11, color: Colors.white),
                              SizedBox(width: 3),
                              Text('Isolation Forest',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _purple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('MỚI',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.devices,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${warning.deviceName ?? ''} · ${warning.location ?? ''}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          warning.warningContent ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isUnread
                                ? const Color(0xFF2F4858)
                                : Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        if (score > 0) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Điểm bất thường',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _purple,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                '${(score * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _purpleDeep,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: score.clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: _purpleBg,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      _purple),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(warning.createdDate),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            _AskAiButton(
                              warning: warning,
                              color: _purple,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProphetCard extends StatelessWidget {
  final Warning warning;
  const _ProphetCard({required this.warning});

  static const _blue     = Color(0xFF1565C0);
  static const _blueDeep = Color(0xFF0D3C75);
  static const _blueBg   = Color(0xFFE8F0FE);
  static const _blueBdr  = Color(0xFF90B8F8);

  @override
  Widget build(BuildContext context) {
    final isUnread = warning.newIcon == true;
    final score    = warning.anomalyScore ?? 0.0;
    final changeStr = '${(score * 100).toStringAsFixed(0)}%';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isUnread ? _blueBg.withValues(alpha: 0.45) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _blueBdr,
          width: isUnread ? 2.0 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _blue.withValues(alpha: isUnread ? 0.14 : 0.06),
            blurRadius: isUnread ? 10 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isUnread)
              Container(
                width: 4,
                decoration: const BoxDecoration(
                  color: _blue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _blueBg,
                      borderRadius: BorderRadius.only(
                        topLeft:  Radius.circular(isUnread ? 0 : 11),
                        topRight: const Radius.circular(11),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.show_chart_rounded,
                            color: _blue, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (warning.warningTitle ?? 'Dự báo tăng tiêu thụ')
                                .replaceFirst(RegExp(r'^\[Prophet\] |\[ML\] '), ''),
                            style: const TextStyle(
                              color: _blueDeep,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _blue,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.timeline_rounded,
                                  size: 11, color: Colors.white),
                              SizedBox(width: 3),
                              Text('Prophet',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('MỚI',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.devices,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${warning.deviceName ?? ''} · ${warning.location ?? ''}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          warning.warningContent ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isUnread
                                ? const Color(0xFF1A2F4A)
                                : Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        if (score > 0) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Mức độ cảnh báo',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _blue,
                                      fontWeight: FontWeight.w600)),
                              Text(
                                '${(score * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: _blueDeep,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: score.clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: _blueBg,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(_blue),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(warning.createdDate),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            _AskAiButton(
                              warning: warning,
                              color: _blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RuleBasedCard extends StatelessWidget {
  final Warning warning;
  const _RuleBasedCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    final style   = _ruleStyle(warning.warningTitle ?? '');
    final isUnread = warning.newIcon == true;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isUnread
            ? style.headerBg.withValues(alpha: 0.35)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnread
              ? style.iconColor.withValues(alpha: 0.5)
              : style.borderColor,
          width: isUnread ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isUnread
                ? style.iconColor.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: isUnread ? 8 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isUnread)
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: style.iconColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: style.headerBg,
                      borderRadius: BorderRadius.only(
                        topLeft:
                            Radius.circular(isUnread ? 0 : 11),
                        topRight: const Radius.circular(11),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(style.icon,
                            color: style.iconColor, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            (warning.warningTitle ?? 'Cảnh báo')
                                .replaceFirst(RegExp(r'^\[AI\] '), ''),
                            style: TextStyle(
                              color: style.iconColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: style.iconColor,
                              borderRadius:
                                  BorderRadius.circular(8),
                            ),
                            child: const Text('MỚI',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(14, 10, 14, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.devices,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${warning.deviceName ?? ''} · ${warning.location ?? ''}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 6),
                        Text(
                          warning.warningContent ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isUnread
                                ? const Color(0xFF2F4858)
                                : Colors.grey.shade600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(warning.createdDate),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            _AskAiButton(
                              warning: warning,
                              color: style.iconColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _RuleStyle _ruleStyle(String title) {
    if (title.contains('bất thường') || title.contains('Bất thường')) {
      return _RuleStyle(
        icon: Icons.warning_amber_rounded,
        iconColor: const Color(0xFFE65100),
        headerBg: const Color(0xFFFFF3E0),
        borderColor: const Color(0xFFFFCC80),
      );
    } else if (title.contains('xu hướng') || title.contains('tăng')) {
      return _RuleStyle(
        icon: Icons.trending_up_rounded,
        iconColor: const Color(0xFFC62828),
        headerBg: const Color(0xFFFFEBEE),
        borderColor: const Color(0xFFEF9A9A),
      );
    } else if (title.contains('lịch') || title.contains('gợi ý')) {
      return _RuleStyle(
        icon: Icons.lightbulb_outline_rounded,
        iconColor: const Color(0xFF2E7D32),
        headerBg: const Color(0xFFE8F5E9),
        borderColor: const Color(0xFFA5D6A7),
      );
    }
    return _RuleStyle(
      icon: Icons.info_outline_rounded,
      iconColor: AppColors.primaryColor,
      headerBg: AppColors.primaryColor.withValues(alpha: 0.1),
      borderColor: AppColors.primaryColor.withValues(alpha: 0.3),
    );
  }
}

class _RuleStyle {
  final IconData icon;
  final Color iconColor;
  final Color headerBg;
  final Color borderColor;

  const _RuleStyle({
    required this.icon,
    required this.iconColor,
    required this.headerBg,
    required this.borderColor,
  });
}

String _formatDate(String? dateStr) {
  if (dateStr == null) return '';
  try {
    final dt = DateTime.parse(dateStr);
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  } catch (_) {
    return dateStr;
  }
}

class _AskAiButton extends StatelessWidget {
  final Warning warning;
  final Color color;

  const _AskAiButton({required this.warning, required this.color});

  String get _buttonLabel {
    if (warning.isProphet) return 'Hỏi AI dự báo ↗';
    final title = warning.warningTitle ?? '';
    if (title.contains('lịch') || title.contains('gợi ý')) {
      return 'Hỏi AI chi tiết ↗';
    }
    return 'Hỏi AI phân tích ↗';
  }

  String get _question {
    final deviceHint = warning.deviceId != null
        ? ' [device_id:${warning.deviceId}]'
        : '';

    if (warning.isMlAnomaly) {
      final score =
          ((warning.anomalyScore ?? 0) * 100).toStringAsFixed(0);
      return 'Mô hình Isolation Forest phát hiện bất thường cho thiết bị '
          '${warning.deviceName} (${warning.location})$deviceHint. '
          '${warning.warningContent} '
          'Điểm bất thường: $score%. '
          'Tra cứu dữ liệu tiêu thụ thiết bị này, phân tích nguyên nhân '
          'và đề xuất cách xử lý cụ thể.';
    }

    if (warning.isProphet) {
      return 'Mô hình Prophet phát hiện xu hướng bất thường cho thiết bị '
          '${warning.deviceName} (${warning.location})$deviceHint. '
          '${warning.warningContent} '
          'Tra cứu dữ liệu lịch sử 30 ngày gần nhất của thiết bị này, '
          'xác nhận xu hướng và đề xuất cách kiểm soát mức tiêu thụ.';
    }

    final title = warning.warningTitle ?? '';
    if (title.contains('lịch') || title.contains('gợi ý')) {
      return 'Hãy cho tôi biết chi tiết về gợi ý "${warning.warningTitle}" '
          'của thiết bị ${warning.deviceName} (${warning.location})$deviceHint. '
          '${warning.warningContent} '
          'Tra cứu dữ liệu sử dụng và đề xuất cách thực hiện.';
    }
    return 'Phân tích chi tiết cảnh báo "${warning.warningTitle}" '
        'của thiết bị ${warning.deviceName} (${warning.location})$deviceHint. '
        'Nội dung: ${warning.warningContent}. '
        'Tra cứu dữ liệu tiêu thụ thiết bị này, phân tích nguyên nhân '
        'và đề xuất cách khắc phục cụ thể.';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _askAi,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              _buttonLabel,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _askAi() {
    final question = _question;
    try {
      Get.find<AiChatController>().inputCtrl.text = question;
    } catch (_) {}
    try {
      Get.find<MainController>().onChangePage(3);
    } catch (_) {}
    Future.delayed(const Duration(milliseconds: 350), () {
      try {
        final ctrl = Get.find<AiChatController>();
        if (ctrl.inputCtrl.text.isNotEmpty) {
          ctrl.sendMessage(ctrl.inputCtrl.text);
        }
      } catch (_) {}
    });
  }
}
