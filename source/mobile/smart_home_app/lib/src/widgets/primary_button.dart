import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    Key? key,
    this.isLoading = false,
    this.child,
    this.onTap,
    this.buttonText = '',
    this.textStyle,
    this.isFullWidth = true,
  }) : super(key: key);

  final bool isLoading;
  final Widget? child;
  final VoidCallback? onTap;
  final bool isFullWidth;
  final String buttonText;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onTap != null && !isLoading
              ? AppColors.buttonGradient
              : const LinearGradient(
                  colors: [Color(0xFFB0BEC5), Color(0xFF90A4AE)]),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (onTap != null && !isLoading)
              BoxShadow(
                color: AppColors.primaryColor.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: isLoading ? null : () {
              FocusScope.of(context).unfocus();
              onTap?.call();
            },
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : child ??
                      Text(
                        buttonText,
                        style: textStyle ??
                            GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
