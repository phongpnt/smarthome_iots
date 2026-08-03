part of 'topic.dart';

Topics _$TopicsFromJson(Map<String, dynamic> json) => Topics(
      topicId: (json['topicId'] as num?)?.toInt(),
      topicName: json['topicName'] as String?,
      deviceId: json['deviceId'] as String?,
      device: json['device'] as String?,
      events: (json['events'] as List<dynamic>?)
          ?.map((e) => Events.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TopicsToJson(Topics instance) => <String, dynamic>{
      'topicId': instance.topicId,
      'topicName': instance.topicName,
      'deviceId': instance.deviceId,
      'device': instance.device,
      'events': instance.events,
    };
