import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: labelText,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        floatingLabelAlignment: FloatingLabelAlignment.start,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.0,
          color: Colors.black.withOpacity(0.4),
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.0,
          color: Colors.black.withOpacity(0.4),
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.fromLTRB(16, 28, 16, 18),
        constraints: const BoxConstraints(minHeight: 72),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      ),
      style: TextStyle(
        fontSize: 16,
        color: Colors.black.withOpacity(0.9),
        height: 1.0,
      ),
      onChanged: onChanged,
    );
  }
}
