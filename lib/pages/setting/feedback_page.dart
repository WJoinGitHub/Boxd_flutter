import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _contentController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _uploadLogs = false;
  bool _isSending = false;

  final List<String> _tags = [
    'App Bug',
    'Connect',
    'Scan',
    'Compatibility issues',
    'Firmware update',
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _sendFeedback() async {
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one question type')),
      );
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter feedback content')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // TODO: 调用API发送反馈
      await Future.delayed(const Duration(seconds: 1)); // 模拟网络请求
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback sent successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send feedback: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(
        title: 'Feedback',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question about section
            const Text(
              'Question about',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return GestureDetector(
                  onTap: () => _toggleTag(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.orange : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.orange : Colors.grey,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Tell me more information section
            const Text(
              'Tell me more information*',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 6,
                minLines: 6,
                maxLength: 200,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'input content',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: AppColors.gray3,
                  ),
                  contentPadding: const EdgeInsets.fromLTRB(16, 18, 16, 40),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                  counterText: '${_contentController.text.length}/200',
                  counterStyle: TextStyle(
                    fontSize: 12,
                    color: AppColors.gray3,
                  ),
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.black1,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(height: 24),

            // Upload logs checkbox
            Row(
              children: [
                Checkbox(
                  value: _uploadLogs,
                  onChanged: (value) {
                    setState(() => _uploadLogs = value ?? false);
                  },
                  activeColor: AppColors.orange,
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _uploadLogs = !_uploadLogs);
                    },
                    child: const Text(
                      'Uploading logs helps us identify and fix the problem faster.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Send button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: (_isSending || _selectedTags.isEmpty || _contentController.text.trim().isEmpty)
                    ? null
                    : _sendFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Send',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

