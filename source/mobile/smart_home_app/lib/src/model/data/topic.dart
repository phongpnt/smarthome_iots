import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:smart_home_app/src/model/data/event.dart';

part 'topic.g.dart';

@JsonSerializable()
class Topics {
  int? topicId;
  String? topicName;
  String? deviceId;
  String? device;
  List<Events>? events;

  Topics(
      {this.topicId, this.topicName, this.deviceId, this.device, this.events});

  Topics.fromJson(Map<String, dynamic> json) {
    topicId = json['topicId'];
    topicName = json['topicName'];
    deviceId = json['deviceId'];
    device = json['device'];
    if (json['events'] != null) {
      events = <Events>[];
      json['events'].forEach((v) {
        events!.add(Events.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['topicId'] = topicId;
    data['topicName'] = topicName;
    data['deviceId'] = deviceId;
    data['device'] = device;
    if (events != null) {
      data['events'] = events!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
