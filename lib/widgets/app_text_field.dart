import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String placeholderText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  const AppTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.placeholderText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 👇 顶部固定说明文字（不会动）
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 6),
          child: Text(
            labelText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.black1,
            ),
          ),
        ),

        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          maxLines: 1,
          decoration: InputDecoration(
            hintText: placeholderText,
            hintStyle: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.gray3,
            ),
            filled: true,
            fillColor: AppColors.fromHex(0xEEF1F0, 0.6), // #EEF1F099
            contentPadding: EdgeInsets.fromLTRB(
              16,
              18,
              suffixIcon != null ? 56 : 16,
              18,
            ),
            constraints: const BoxConstraints(minHeight: 72, maxHeight: 72),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: BorderSide.none,
            ),
            suffixIcon: suffixIcon,
          ),
          style: TextStyle(
            fontSize: 16,
            color: AppColors.black1,
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
