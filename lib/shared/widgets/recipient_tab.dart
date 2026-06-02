import 'package:flutter/material.dart';
import 'package:kudipay/core/theme/app_theme.dart';


class RecipientTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const RecipientTabBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  static const List<String> tabs = ['Contact', 'Recent', 'Phone No.'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(tabs.length, (index) {
        final isSelected = selectedIndex == index;
        return Expanded(
          child: GestureDetector(
            onTap: () => onTabChanged(index),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tabs[index],
                    style: isSelected
                        ? AppTextStyles.tabActive
                        : AppTextStyles.tabInactive,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 2,
                    width: isSelected ? 40 : 0,
                    decoration: BoxDecoration(
                      color: Color(0xFF069494),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}