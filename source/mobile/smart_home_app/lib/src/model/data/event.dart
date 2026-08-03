import 'package:freezed_annotation/freezed_annotation.dart';

part 'event.g.dart';

@JsonSerializable()
class Events {
  String? eventId;
  String? createdDate;
  String? value;
  int? topicId;
  String? topic;

  Events(
      {this.eventId, this.createdDate, this.value, this.topicId, this.topic});

  Events.fromJson(Map<String, dynamic> json) {
    eventId = json['eventId'];
    createdDate = json['createdDate'];
    value = json['value'];
    topicId = json['topicId'];
    topic = json['topic'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['eventId'] = eventId;
    data['createdDate'] = createdDate;
    data['value'] = value;
    data['topicId'] = topicId;
    data['topic'] = topic;
    return data;
  }
}
