import 'package:intl/intl.dart';
import 'package:smart_home_app/src/repository/ipower_usage_repository.dart';

extension StringDateTimeExt on String {
  DateTime toDateTime() {
    return DateTime.parse(this);
  }

  String toLocal() {
    final DateTime dateTime = DateTime.parse(this).toLocal();
    return dateTime.toIso8601String();
  }

  DateTime get toLocalDT {
    return DateTime.parse(this).toLocal();
  }

  String get HH_mm {
    final DateTime dateTime = DateTime.parse(this).toLocal();
    return DateFormat('HH:mm').format(dateTime);
  }

  String get dd_MM_yyy {
    final DateTime dateTime = DateTime.parse(this).toLocal();
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  String get dd_MM {
    final DateTime dateTime = DateTime.parse(this).toLocal();
    return DateFormat('dd').format(dateTime);
  }

  String get EEEE_dd_MM_yyyy {
    final DateTime dateTime = DateTime.parse(this).toLocal();
    return DateFormat('EEEE, dd/MM/yyyy').format(dateTime);
  }
}

extension DateTimeExt2 on DateTime {
  DateTime get startDay {
    return DateTime(year, month, day, 0, 0);
  }

  DateTime get endDay {
    return DateTime(year, month, day, 23, 59);
  }

  String get HH_mm {
    return DateFormat('HH:mm').format(this);
  }

  String get dd_MM_yyy {
    return DateFormat('dd-MM-yyyy').format(this);
  }

  String get EEEE_dd_MM_yyyy {
    return DateFormat('EEEE, dd/MM/yyyy').format(this);
  }

  String get EEEE_dd_MM_yyy {
    return DateFormat("EEEE , dd-MM-yyyy").format(this);
  }

  bool get isBeforeNow {
    final now = DateTime.now();
    if (now.year == year) {
      if (now.month == month) {
        return now.day > day;
      } else if (now.month < month) {
        return true;
      } else {
        return false;
      }
    } else if (now.year < year) {
      return true;
    }
    return false;
  }
}

extension DurationExt on Duration {
  String format() {
    final minutes = inMinutes.remainder(60);
    return "${inHours < 10 ? "0$inHours" : inHours}:${minutes < 10 ? "0$minutes" : minutes}";
  }
}

extension ChartFilterExten on ChartFilter {
  String get filterName {
    switch (this) {
      case ChartFilter.week:
        return 'Week';
      case ChartFilter.month:
        return 'Month';
      case ChartFilter.day:
        return 'Day';
    }
  }
}
