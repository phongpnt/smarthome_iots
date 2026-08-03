import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_home_app/src/base/base_page.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';

abstract class BaseLoginPage<T extends GetLifeCycleBase> extends BasePage<T> {
  double get radiusView => 28;
  Color get bodyBackground => Colors.white;

  @override
  bool get resizeToAvoidBottomInset => true;

  @override
  Widget buildChild(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Flexible(
            flex: 4,
            child: _HeroSection(),
          ),

          Flexible(
            flex: 6,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: bodyBackground,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(radiusView)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: bodyPadding,
                child: buildBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  EdgeInsets get bodyPadding =>
      const EdgeInsets.fromLTRB(24, 28, 24, 32);

  Widget buildBody();
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8), Color(0xFF2563EB)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.35), width: 1.5),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    size: 34,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _FloatingBadge(Icons.wifi_rounded, const Color(0xFF60A5FA)),
                ),
                Positioned(
                  bottom: 8,
                  left: 4,
                  child: _FloatingBadge(Icons.bolt_rounded, const Color(0xFFFBBF24)),
                ),
                Positioned(
                  bottom: 6,
                  right: 2,
                  child: _FloatingBadge(Icons.device_thermostat_rounded, const Color(0xFF34D399)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            Text(
              'Smart Home',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Điều khiển ngôi nhà thông minh',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.70),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _Pill(icon: Icons.security_rounded, label: 'Bảo mật'),
                SizedBox(width: 8),
                _Pill(icon: Icons.bolt_rounded, label: 'Tiết kiệm'),
                SizedBox(width: 8),
                _Pill(icon: Icons.tune_rounded, label: 'Tự động'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge(this.icon, this.color);
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color.withOpacity(0.20),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.50), width: 1),
      ),
      child: Icon(icon, size: 13, color: color),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withOpacity(0.85)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}
