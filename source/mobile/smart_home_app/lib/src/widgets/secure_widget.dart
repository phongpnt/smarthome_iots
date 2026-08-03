import 'package:flutter/material.dart';

class SecureWidget extends StatelessWidget {
  const SecureWidget({Key? key, this.value = false, required this.onTap})
      : super(key: key);
  final Function() onTap;
  final bool value;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: value
          ? const Icon(Icons.visibility_off_outlined)
          : const Icon(Icons.visibility_outlined),
    );
  }
}
