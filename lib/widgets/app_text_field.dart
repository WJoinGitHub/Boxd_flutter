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
        labelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.gray3,
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: AppColors.gray3,
        ),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.fromLTRB(13, 30, 13, 10),
        constraints: const BoxConstraints(minHeight: 64),
        alignLabelWithHint: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        suffixIcon: suffixIcon,
      ),
      style: TextStyle(
        fontSize: 13,
        color: AppColors.black1,
      ),
      onChanged: onChanged,
    );
  }
}
