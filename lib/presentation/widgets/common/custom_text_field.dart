import 'package:flutter/material.dart';

// 自定义文本输入框组件
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final FocusNode? focusNode;
  final bool readOnly;
  final VoidCallback? onTap;
  final Color? borderColor;
  final Color? focusedBorderColor;
  final double borderRadius;
  final double fontSize;
  final double iconSize;
  final EdgeInsetsGeometry? contentPadding;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
    this.borderColor,
    this.focusedBorderColor,
    this.borderRadius = 4,
    this.fontSize = 14,
    this.iconSize = 20,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        onChanged: onChanged,
        focusNode: focusNode,
        readOnly: readOnly,
        onTap: onTap,
        autofocus: false,
        style: TextStyle(fontSize: fontSize),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey, fontSize: fontSize - 2),
          prefixIcon: Icon(prefixIcon, size: iconSize, color: Colors.grey),
          border: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor ?? Colors.grey),
            borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: borderColor ?? Colors.grey),
            borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: focusedBorderColor ?? Colors.blue),
            borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        ),
      ),
    );
  }
}