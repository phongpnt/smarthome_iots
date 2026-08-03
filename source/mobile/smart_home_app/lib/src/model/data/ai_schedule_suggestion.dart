import 'package:smart_home_app/src/model/data/schedule.dart';
import 'package:uuid/uuid.dart';

class AiScheduleSuggestion {
  final String deviceId;
  final String deviceName;
  final String location;
  final String time;  // "HH:mm"
  final String dayOfWeek;  // "1234567"
  final bool powerStatus;  // true = BẬT
  final String reason;
  final String label;

  const AiScheduleSuggestion({
    required this.deviceId,
    required this.deviceName,
    required this.location,
    required this.time,
    required this.dayOfWeek,
    required this.powerStatus,
    required this.reason,
    required this.label,
  });

  factory AiScheduleSuggestion.fromJson(Map<String, dynamic> json) =>
      AiScheduleSuggestion(
        deviceId:    json['deviceId']    as String? ?? '',
        deviceName:  json['deviceName']  as String? ?? '',
        location:    json['location']    as String? ?? '',
        time:        json['time']        as String? ?? '08:00',
        dayOfWeek:   json['dayOfWeek']   as String? ?? '1234567',
        powerStatus: json['powerStatus'] as bool?   ?? true,
        reason:      json['reason']      as String? ?? '',
        label:       json['label']       as String? ?? '',
      );

  Schedule toSchedule() => Schedule(
        id:          const Uuid().v4(),  // backend không tự gen ID
        deviceId:    deviceId,
        time:        _normalizeTime(time),
        dayOfWeek:   dayOfWeek.isEmpty ? '1234567' : dayOfWeek,
        powerStatus: powerStatus,
        active:      true,
        description: label.isEmpty ? (powerStatus ? 'Bật thiết bị' : 'Tắt thiết bị') : label,
      );

  static String _normalizeTime(String t) {
    try {
      final parts = t.split(':');
      if (parts.length < 2) return '08:00';
      final h = int.parse(parts[0]).clamp(0, 23);
      final m = int.parse(parts[1]).clamp(0, 59);
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    } catch (_) {
      return '08:00';
    }
  }

  String get dayText {
    if (dayOfWeek.isEmpty ||
        dayOfWeek.split('').toSet().containsAll(['1','2','3','4','5','6','7'])) {
      return 'Mỗi ngày';
    }
    const map = {
      '1': 'T2', '2': 'T3', '3': 'T4',
      '4': 'T5', '5': 'T6', '6': 'T7', '7': 'CN',
    };
    return dayOfWeek.split('').map((d) => map[d] ?? d).join(' · ');
  }
}
