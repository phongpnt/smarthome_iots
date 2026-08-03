import 'package:smart_home_app/src/controllers/smart_home_data.dart';

class SmartHomeDevice {
  int? id;
  String? title;
  String? category;
  SmartHomeType? homeType;

  SmartHomeDevice({
    this.id,
    this.title,
    this.category,
    this.homeType,
  });
}
