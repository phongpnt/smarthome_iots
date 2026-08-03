import 'package:flutter/material.dart';
import 'package:smart_home_app/src/config/app_them.dart';
import 'package:smart_home_app/src/widgets/secure_widget.dart';
import 'package:smart_home_app/src/widgets/text_field/custom_text_field_model.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    Key? key,
    required this.model,
    this.hint = '',
    this.suffixWidget,
    this.obscureText,
    this.paddingLine = 5,
    this.isPassword = false,
  }) : super(key: key);

  final CustomTextFieldModel model;
  final String hint;
  final Widget? suffixWidget;
  final bool? obscureText;
  final double paddingLine;
  final bool isPassword;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late final ValueNotifier<bool> _secureToggle =
      ValueNotifier(widget.isPassword);

  @override
  void dispose() {
    _secureToggle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _secureToggle,
          builder: (context, value, child) => TextField(
            controller: widget.model.controller,
            obscureText: value,
            decoration: TextFormDecoration(
              context: context,
              hint: widget.hint,
              fillColor: Colors.transparent,
              suffixWidget: widget.isPassword
                  ? widget.suffixWidget ??
                      SecureWidget(
                          onTap: () =>
                              _secureToggle.value = !_secureToggle.value,
                          value: _secureToggle.value)
                  : widget.suffixWidget,
            ),
          ),
        ),
        StreamBuilder<String>(
          stream: widget.model.errorStream,
          initialData: '',
          builder: (context, snapshot) {
            final text = snapshot.data ?? '';
            if (text.isEmpty) return const SizedBox();
            return Padding(
              padding: EdgeInsets.symmetric(vertical: widget.paddingLine),
              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: Colors.red),
              ),
            );
          },
        )
      ],
    );
  }
}
