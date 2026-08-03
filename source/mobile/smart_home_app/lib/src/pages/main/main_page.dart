import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:smart_home_app/src/base/base_page.dart';
import 'package:smart_home_app/src/config/responsive.dart';
import 'package:smart_home_app/src/consts/app_colors.dart';
import 'package:smart_home_app/src/pages/ai_chat/ai_chat_page.dart';
import 'package:smart_home_app/src/pages/home/home_page.dart';
import 'package:smart_home_app/src/pages/main/main_controller.dart';
import 'package:smart_home_app/src/pages/power_usage/power_usage_page.dart';
import 'package:smart_home_app/src/pages/profile.dart';
import 'package:smart_home_app/src/pages/smart_home/smart_home_page.dart';

class MainPage extends BasePage<MainController> {
  List<Widget> _buildScreens() {
    return [
      HomePage(),
      SmartHomePage(),
      PowerUsagePage(),
      const AiChatPage(),
      ProfilePage(),
    ];
  }

  @override
  Widget buildChild(BuildContext context) => const SizedBox();

  @override
  Widget build(BuildContext context) {
    final bottomItems = [
      _NavItem(label: 'Trang chủ',  icon: Icons.home_outlined,        activeIcon: Icons.home),
      _NavItem(label: 'Lịch hẹn',  icon: Icons.tune_outlined,         activeIcon: Icons.tune),
      _NavItem(label: 'Tiêu thụ',  icon: Icons.pie_chart_outline,     activeIcon: Icons.pie_chart,  badgeIndex: 2),
      _NavItem(label: 'Trợ lý AI', icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome),
      _NavItem(label: 'Hồ sơ',     icon: Icons.person_outline,        activeIcon: Icons.person),
    ];

    return Obx(() {
      final screens = _buildScreens();
      final current = controller.currentIndex.value;
      final warningCount = controller.unreadWarnings.value;

      return Scaffold(
        backgroundColor: AppColors.morelightgrey,
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                itemCount: screens.length,
                itemBuilder: (_, i) => screens[i],
                controller: controller.pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  )
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: setPadding(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: bottomItems.asMap().entries.map((e) {
                      final idx = e.key;
                      final item = e.value;
                      final isActive = current == idx;
                      final badge = (item.badgeIndex == idx && warningCount > 0)
                          ? warningCount
                          : 0;

                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => controller.onChangePage(idx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: isActive
                              ? setPadding(horizontal: 14, vertical: 8)
                              : setPadding(horizontal: 12, vertical: 8),
                          decoration: isActive
                              ? BoxDecoration(
                                  color: AppColors.primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                )
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    isActive ? item.activeIcon : item.icon,
                                    size: 24,
                                    color: isActive
                                        ? AppColors.primaryColor
                                        : const Color(0xFF9E9E9E),
                                  ),
                                  if (badge > 0)
                                    Positioned(
                                      top: -6,
                                      right: -8,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                              color: Colors.white, width: 1.5),
                                        ),
                                        child: Text(
                                          badge > 99 ? '99+' : '$badge',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (isActive) ...[
                                const SizedBox(width: 6),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: AppColors.primaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int? badgeIndex;  // tab index muốn hiện badge

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badgeIndex,
  });
}

class BottomNavItem {
  final String label;
  final IconData iconData;
  BottomNavItem({this.label = '', required this.iconData});
}
