import 'package:flutter/material.dart';

// 自定义文本输入框组件
class CustomTextField extends StatefulWidget {
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
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        onChanged: widget.onChanged,
        focusNode: widget.focusNode,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        autofocus: false,
        style: TextStyle(fontSize: widget.fontSize),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey, fontSize: widget.fontSize - 2),
          prefixIcon: Icon(widget.prefixIcon, size: widget.iconSize, color: Color.fromARGB(255, 230, 228, 228)),
          suffixIcon: widget.obscureText ? IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
              size: widget.iconSize,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
            style: IconButton.styleFrom(
              splashFactory: NoSplash.splashFactory,
            ),
          ) : null,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: widget.borderColor ?? Colors.grey),
            borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: widget.borderColor ?? Colors.grey),
            borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius)),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: widget.focusedBorderColor ?? Colors.blue),
            borderRadius: BorderRadius.all(Radius.circular(widget.borderRadius)),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: widget.contentPadding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        ),
        // 添加键盘相关配置
        textInputAction: TextInputAction.next,
        enableSuggestions: false,
        autocorrect: false,
      ),
    );
  }
}