import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/model/data/ai_schedule_suggestion.dart';
import 'package:smart_home_app/src/model/data/schedule.dart';
import 'package:smart_home_app/src/repository/ipower_usage_repository.dart';
import 'package:smart_home_app/src/service/account_service.dart';
import 'package:smart_home_app/src/service/device_service.dart';
import 'package:smart_home_app/src/repository/idevice_repository.dart';

class AiScheduleSheet extends StatefulWidget {
  const AiScheduleSheet({super.key});

  @override
  State<AiScheduleSheet> createState() => _AiScheduleSheetState();
}

class _AiScheduleSheetState extends State<AiScheduleSheet> {
  bool _loading = true;
  String? _error;
  List<AiScheduleSuggestion> _suggestions = [];

  final Set<int> _applied  = {};
  final Set<int> _applying = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final userId = Get.find<AccountService>().account?.userId ?? '';
      final repo   = Get.find<IPowerUsageRepository>();
      final result = await repo.getScheduleSuggestions(userId);
      if (mounted) {
        setState(() {
          _suggestions = result;
          _loading     = false;
          if (result.isEmpty) {
            _error = 'AI chưa tìm thấy pattern đủ rõ ràng.\n'
                     'Hệ thống cần ít nhất vài ngày sử dụng mỗi thiết bị.';
          }
        });
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[AiScheduleSheet] error: $msg');
      if (mounted) {
        setState(() {
          _loading = false;
          _error   = 'Lỗi phân tích:\n$msg';
        });
      }
    }
  }

  List<Schedule> _duplicatesFor(AiScheduleSuggestion s) {
    final existing = Get.find<DeviceService>().schedules.value ?? [];
    return existing.where((e) =>
      e.deviceId   == s.deviceId &&
      e.time       == s.time &&
      (e.powerStatus ?? false) == s.powerStatus
    ).toList();
  }

  Future<void> _apply(int index) async {
    if (_applied.contains(index) || _applying.contains(index)) return;

    final s          = _suggestions[index];
    final duplicates = _duplicatesFor(s);

    if (duplicates.isNotEmpty) {
      final confirm = await _showDuplicateDialog(s, duplicates);
      if (confirm != true) return;
    }

    setState(() => _applying.add(index));

    try {
      final schedule = s.toSchedule();
      final repo     = Get.find<IDeviceResponsitory>();
      final created  = await repo.onAddSchedule(schedule);

      if (!mounted) return;

      if (created != null) {
        Get.find<DeviceService>().onAddSchedule(created);
        setState(() { _applied.add(index); _applying.remove(index); });
        Get.snackbar(
          'Đã áp dụng',
          '"${s.label}" đã được thêm vào lịch',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green.shade50,
          colorText: Colors.green.shade800,
          icon: const Icon(Icons.check_circle, color: Colors.green),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(12),
        );
      } else {
        setState(() => _applying.remove(index));
        Get.snackbar(
          'Không thể áp dụng',
          'Server từ chối lịch này. Kiểm tra lại thiết bị.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange.shade50,
          colorText: Colors.orange.shade800,
        );
      }
    } catch (e) {
      if (mounted) setState(() => _applying.remove(index));
      Get.snackbar('Lỗi', 'Không thể tạo lịch: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade50,
          colorText: Colors.red.shade800);
    }
  }

  Future<bool?> _showDuplicateDialog(
      AiScheduleSuggestion s, List<Schedule> duplicates) {
    final dupText = duplicates.map((d) =>
        '• ${d.description ?? (d.powerStatus == true ? "Bật" : "Tắt")} '
        '${d.time} (${d.dayText})').join('\n');

    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.orange.shade700, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Lịch bị trùng',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Đã có ${duplicates.length} lịch tương tự cho '
              '"${s.deviceName}" lúc ${s.time}:',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Text(dupText,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                      height: 1.6)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bạn có muốn tạo thêm lịch này không?',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Tạo thêm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize:     0.5,
      maxChildSize:     0.95,
      expand:           false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.auto_awesome,
                        color: AppColors.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('AI gợi ý lịch',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primaryColor)),
                        Text('Dựa trên thói quen sử dụng 30 ngày qua',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close, size: 20)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildBody(scrollCtrl)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ScrollController scrollCtrl) {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: AppColors.primaryColor),
            SizedBox(height: 16),
            Text('AI đang phân tích thói quen sử dụng...',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 14, height: 1.6)),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    return Obx(() {
      Get.find<DeviceService>().schedules.value;
      return ListView.builder(
        controller:  scrollCtrl,
        padding:     const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount:   _suggestions.length,
        itemBuilder: (_, i) {
          final duplicates = _duplicatesFor(_suggestions[i]);
          return _SuggestionCard(
            suggestion:  _suggestions[i],
            applied:     _applied.contains(i),
            applying:    _applying.contains(i),
            duplicates:  duplicates,
            onApply:     () => _apply(i),
          );
        },
      );
    });
  }
}

class _SuggestionCard extends StatelessWidget {
  final AiScheduleSuggestion suggestion;
  final bool applied;
  final bool applying;
  final List<Schedule> duplicates;
  final VoidCallback onApply;

  const _SuggestionCard({
    required this.suggestion,
    required this.applied,
    required this.applying,
    required this.duplicates,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final isOn       = suggestion.powerStatus;
    final color      = isOn ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final bgColor    = isOn ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final icon       = isOn ? Icons.power_settings_new : Icons.power_off_outlined;
    final hasDup     = duplicates.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: applied
              ? Colors.green.shade300
              : hasDup
                  ? Colors.orange.shade300
                  : Colors.grey.shade200,
          width: hasDup ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
              color: hasDup
                  ? Colors.orange.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(suggestion.label,
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
                if (hasDup) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 11, color: Colors.white),
                        const SizedBox(width: 3),
                        Text('${duplicates.length} trùng',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(8)),
                  child: Text(isOn ? 'BẬT' : 'TẮT',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          if (hasDup)
            Container(
              margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 13, color: Colors.orange.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'Đã có ${duplicates.length} lịch tương tự:',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ...duplicates.map((d) => Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '• ${d.description ?? (d.powerStatus == true ? "Bật" : "Tắt")} '
                          '${d.time} · ${d.dayText}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade900,
                              height: 1.4),
                        ),
                      )),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.devices, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${suggestion.deviceName} · ${suggestion.location}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.grey)),
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  _InfoChip(
                    icon:  Icons.access_time,
                    text:  suggestion.time,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon:  Icons.calendar_today,
                    text:  suggestion.dayText,
                    color: Colors.blueGrey,
                  ),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.auto_awesome,
                          size: 13, color: AppColors.primaryColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(suggestion.reason,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF2F4858),
                                height: 1.5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: applied
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color:  Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle,
                                  size: 16, color: Colors.green.shade600),
                              const SizedBox(width: 6),
                              Text('Đã áp dụng',
                                  style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: applying ? null : onApply,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: hasDup
                                ? Colors.orange.shade700
                                : AppColors.primaryColor,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: applying
                              ? const SizedBox(
                                  width:  18, height: 18,
                                  child:  CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      hasDup
                                          ? Icons.warning_amber_rounded
                                          : Icons.add_circle_outline,
                                      size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      hasDup
                                          ? 'Áp dụng (có trùng)'
                                          : 'Áp dụng lịch này',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                  ],
                                ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoChip(
      {required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:        color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
