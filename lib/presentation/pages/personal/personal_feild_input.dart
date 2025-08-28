import 'package:flutter/material.dart';

class PasswordInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const PasswordInputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.errorText,
    this.onChanged,
  });

  @override
  State<PasswordInputField> createState() => _PasswordInputFieldState();
}

class _PasswordInputFieldState extends State<PasswordInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            color: Color.fromARGB(255, 124, 123, 123),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: (widget.errorText != null && widget.errorText!.isNotEmpty)
                  ? Colors.red.shade400
                  : Colors.grey.shade300,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: _obscureText,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(
                  color: Color.fromARGB(255, 197, 196, 196), fontSize: 13),
              prefixIcon: Icon(widget.icon,
                  color: const Color.fromARGB(255, 180, 179, 179), size: 16),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                  color: const Color.fromARGB(255, 207, 206, 206),
                  size: 16,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 14),
            onChanged: widget.onChanged,
          ),
        ),
        if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.errorText!,
            style: TextStyle(fontSize: 11, color: Colors.red.shade600),
          ),
        ],
      ],
    );
  }
}
