import 'dart:async';

import 'package:flutter/material.dart';

class CustomTextFieldModel {
  final bool isRequired;
  final controller = TextEditingController();
  final bool Function(String) validate;
  final String errorValidateText;

  var _errorText = '';
  final _errorStream = StreamController<String>.broadcast();

  Stream<String> get errorStream => _errorStream.stream;

  String get text => controller.text;

  String get errorText {
    return _errorText;
  }

  set errorText(String value) {
    _errorText = value;
    _errorStream.add(value);
  }

  CustomTextFieldModel({
    this.errorValidateText = '',
    required this.isRequired,
    required this.validate,
  }) {
    controller.addListener(() {
      if (errorText.isNotEmpty) {
        errorText = '';
      }
    });
  }

  void dispose() {
    _errorStream.close();
    controller.dispose();
  }

  bool onValidate() {
    if (isRequired && controller.text.isEmpty) {
      errorText = 'Không được bỏ trống';
      return false;
    }
    if (validate(controller.text)) {
      return true;
    } else {
      errorText = errorValidateText;
      return false;
    }
  }
}
