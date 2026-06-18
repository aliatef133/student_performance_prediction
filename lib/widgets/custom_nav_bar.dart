import 'package:flutter/material.dart';

class CustomNavBarItem extends StatelessWidget {
  final int selectedIndex;
  final int navBarItemIndex;
  final String iconPath;

  const CustomNavBarItem({
    super.key,
    required this.selectedIndex,
    required this.navBarItemIndex,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        color: selectedIndex == navBarItemIndex
            ? Colors.white.withOpacity(0.5) //
            : Colors.transparent,
      ),
      child: ImageIcon(
        AssetImage(iconPath),
      ),
    );
  }
}
