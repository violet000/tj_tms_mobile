import 'package:flutter/material.dart';
import 'package:tj_tms_mobile/presentation/widgets/common/custom_text_field.dart';

class FaceInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const FaceInputWidget({
    Key? key,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  State<FaceInputWidget> createState() => _FaceInputWidgetState();
}

class _FaceInputWidgetState extends State<FaceInputWidget> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: widget.controller,
      hintText: '请输入柜员号',
      prefixIcon: Icons.person,
      onTap: () {
        _focusNode.unfocus();
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请输入柜员号';
        }
        return null;
      },
      onChanged: widget.onChanged,
      focusNode: _focusNode,
    );
  }
}
