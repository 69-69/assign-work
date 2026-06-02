import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/text_field/custom_text_field.dart';
import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onFieldSubmitted;
  final FocusNode? focusNode;

  const ChatInput({
    super.key,
    required this.controller,
    this.onFieldSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return _buildChatInput();
  }

  Widget _buildChatInput() {
    return CustomTextField(
      key: const Key('live_chat_support_field'),
      autofocus: true,
      focusNode: focusNode,
      controller: controller,
      textInputType: TextInputType.none,
      textInputAction: TextInputAction.send,
      onFieldSubmitted: (_) => onFieldSubmitted?.call(),
      inputDecoration: InputDecoration(
        isDense: true,
        filled: true,
        contentPadding: const EdgeInsets.all(1.0),
        hintText: 'Enter your message...',
        label: const Text('Live Support'),
        alignLabelWithHint: true,
        fillColor: kWhiteColor,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Icon(Icons.support_agent, size: 15),
        suffixIcon: IconButton(
          icon: const Icon(Icons.send, color: kPrimaryLightColor),
          onPressed: onFieldSubmitted,
        ),
      ),
    );
  }
}
