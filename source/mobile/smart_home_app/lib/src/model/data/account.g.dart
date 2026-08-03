part of 'account.dart';

Account _$AccountFromJson(Map<String, dynamic> json) => Account(
      userId: json['userId'] as String?,
      passKey: json['passKey'] as String?,
      fullName: json['fullName'] as String?,
      createdDate: json['createdDate'] as String?,
      email: json['email'] as String?,
      active: json['active'] as bool?,
      lastLogin: json['lastLogin'] as String?,
      devices: (json['devices'] as List<dynamic>?)
          ?.map((e) => Devices.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AccountToJson(Account instance) => <String, dynamic>{
      'userId': instance.userId,
      'passKey': instance.passKey,
      'fullName': instance.fullName,
      'createdDate': instance.createdDate,
      'email': instance.email,
      'active': instance.active,
      'lastLogin': instance.lastLogin,
      'devices': instance.devices,
    };
