import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/theme_provider.dart';

class EmergencyContainer extends StatelessWidget {
  final String icon;
  final Color color;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const EmergencyContainer({
    Key? key,
    required this.icon,
    required this.color,
    required this.label,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
 

    return GestureDetector(
      onTap: onTap,
      child: IntrinsicWidth(
        child: Container(
          constraints: const BoxConstraints(),
          height: 54,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color:
                isSelected ? color.withOpacity(0.6) : const Color(0xFFEFEFEF),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Image.asset(icon),
                    ),
                  ),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  color: isSelected
                      ? Colors.black
                      : (themeProvider.isDarkMode
                          ? Colors.black
                          : Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
