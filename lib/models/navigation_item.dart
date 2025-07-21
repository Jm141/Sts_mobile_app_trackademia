import 'package:flutter/material.dart';

class NavigationItem {
  final String title;
  final IconData icon;
  final IconData selectedIcon;
  final bool isBottom;
  final VoidCallback? onTap;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.selectedIcon,
    this.isBottom = false,
    this.onTap,
  });
} 