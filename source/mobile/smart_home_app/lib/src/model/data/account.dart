import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:smart_home_app/src/model/data/device.dart';

part 'account.g.dart';

@JsonSerializable()
class Account {
  String? userId;
  String? passKey;
  String? fullName;
  String? createdDate;
  String? email;
  bool? active;
  String? lastLogin;
  List<Devices>? devices;

  Account(
      {this.userId,
      this.passKey,
      this.fullName,
      this.createdDate,
      this.email,
      this.active,
      this.lastLogin,
      this.devices});

  Account.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    passKey = json['passKey'];
    fullName = json['fullName'];
    createdDate = json['createdDate'];
    email = json['email'];
    active = json['active'];
    lastLogin = json['lastLogin'];
    if (json['devices'] != null) {
      devices = <Devices>[];
      json['devices'].forEach((v) {
        devices!.add(Devices.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['userId'] = userId;
    data['passKey'] = passKey;
    data['fullName'] = fullName;
    data['createdDate'] = createdDate;
    data['email'] = email;
    data['active'] = active;
    data['lastLogin'] = lastLogin;
    if (devices != null) {
      data['devices'] = devices!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  Account copyWith({
    String? userId,
    String? passKey,
    String? fullName,
    String? createdDate,
    String? email,
    bool? active,
    String? lastLogin,
    List<Devices>? devices,
  }) {
    return Account(
      userId: userId ?? this.userId,
      passKey: passKey ?? this.passKey,
      fullName: fullName ?? this.fullName,
      createdDate: createdDate ?? this.createdDate,
      email: email ?? this.email,
      active: active ?? this.active,
      lastLogin: lastLogin ?? this.lastLogin,
      devices: devices ?? this.devices,
    );
  }
}
