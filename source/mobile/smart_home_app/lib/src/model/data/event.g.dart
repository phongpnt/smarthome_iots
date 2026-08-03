part of 'event.dart';

Events _$EventsFromJson(Map<String, dynamic> json) => Events(
      eventId: json['eventId'] as String?,
      createdDate: json['createdDate'] as String?,
      value: json['value'] as String?,
      topicId: (json['topicId'] as num?)?.toInt(),
      topic: json['topic'] as String?,
    );

Map<String, dynamic> _$EventsToJson(Events instance) => <String, dynamic>{
      'eventId': instance.eventId,
      'createdDate': instance.createdDate,
      'value': instance.value,
      'topicId': instance.topicId,
      'topic': instance.topic,
    };
