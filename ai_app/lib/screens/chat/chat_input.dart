import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/colors.dart';

class ChatInput extends StatefulWidget {
  final Function(String, {String? fileUrl}) onSend;

  const ChatInput({
    super.key,
    required this.onSend,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // File attachment button
          GestureDetector(
            onTap: () async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.any,
                  allowMultiple: false,
                );

                if (result != null && result.files.single.path != null) {
                  final fileName = result.files.single.name;
                  
                  // For now, we'll just show the file name
                  // In production, you'd upload to Firebase Storage and get URL
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('File selected: $fileName\n(Upload to Firebase Storage not implemented yet)'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  
                  // Call onSend with file path (you'll need to upload to Firebase Storage first)
                  // widget.onSend('', fileUrl: filePath);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error picking file: $e'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.attach_file, color: AppColors.purple, size: 22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: "Type your message...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () {
              if (controller.text.trim().isEmpty) return;
              widget.onSend(controller.text.trim());
              controller.clear();
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.purple,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward, color: Colors.white),
            ),
          )
        ],
      ),
    );
  }
}