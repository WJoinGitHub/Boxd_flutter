import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _contentController = TextEditingController();
  final Set<String> _selectedTags = {}; // 存储选中的 value
  bool _uploadLogs = false;
  bool _isSending = false;
  List<Map<String, dynamic>> _categories = []; // 存储从接口获取的分类列表

  // 临时标签（如果接口加载失败时使用）
  final List<String> _fallbackTags = [
    'App Bug',
    'Connect',
    'Scan',
    'Compatibility issues',
    'Firmware update',
  ];

  @override
  void initState() {
    super.initState();
    _loadFeedbackCategories();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedbackCategories() async {
    try {
      final result = await ApiClient.getFeedbackCategories(
        page: 1,
        limit: 20,
        isEnabled: 'all',
      );

      // 打印返回结果
      print('[FEEDBACK] 反馈类型接口返回结果:');
      print('[FEEDBACK] 完整响应: $result');

      // 解析 categories
      if (result['code'] == 200 && result['data'] != null) {
        final data = result['data'] as Map<String, dynamic>;
        if (data['categories'] != null && data['categories'] is List) {
          final categories =
              List<Map<String, dynamic>>.from(data['categories']);
          print('[FEEDBACK] 解析到 ${categories.length} 个分类');
          if (mounted) {
            setState(() {
              _categories = categories;
            });
          }
        }
      }
    } catch (e) {
      print('[FEEDBACK] 获取反馈类型失败: $e');
      // 如果接口失败，使用备用标签
      if (mounted && _categories.isEmpty) {
        setState(() {
          _categories = _fallbackTags
              .map((tag) => {
                    'label': tag,
                    'value': tag.toLowerCase().replaceAll(' ', '_'),
                  })
              .toList();
        });
      }
    }
  }

  void _toggleTag(String value) {
    setState(() {
      if (_selectedTags.contains(value)) {
        _selectedTags.remove(value);
      } else {
        _selectedTags.add(value);
      }
    });
  }

  /// 获取设备信息
  Future<String> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}';
      }
    } catch (e) {
      print('[FEEDBACK] 获取设备信息失败: $e');
    }
    return 'Unknown Device';
  }

  /// 获取系统版本
  Future<String> _getSystemVersion() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      }
    } catch (e) {
      print('[FEEDBACK] 获取系统版本失败: $e');
    }
    return 'Unknown';
  }

  /// 获取应用版本
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version} (${packageInfo.buildNumber})';
    } catch (e) {
      print('[FEEDBACK] 获取应用版本失败: $e');
      return 'Unknown';
    }
  }

  Future<void> _sendFeedback() async {
    final l10n = AppLocalizations.of(context);
    // 判断用户是否有输入
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('select_question_type'))),
      );
      return;
    }

    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.t('enter_feedback_content'))),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      // 取第一个选中的标签的 value 作为 category
      final category = _selectedTags.first;

      // 获取设备信息、系统版本和应用版本
      final deviceInfo = await _getDeviceInfo();
      final systemVersion = await _getSystemVersion();
      final appVersion = await _getAppVersion();

      // TODO: 如果 _uploadLogs 为 true，需要上传日志并获取 attachment_url
      String? attachmentUrl;
      if (_uploadLogs) {
        // 这里可以添加上传日志的逻辑
        // attachmentUrl = await _uploadLogs();
      }

      final result = await ApiClient.submitFeedback(
        category: category,
        content: content,
        appVersion: appVersion,
        deviceInfo: deviceInfo,
        systemVersion: systemVersion,
        attachmentUrl: attachmentUrl,
      );

      if (mounted) {
        if (result['code'] == 200 || result['code'] == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('feedback_submitted'))),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? l10n.t('feedback_failed')),
            ),
          );
        }
      }
    } catch (e) {
      print('[FEEDBACK] 提交反馈失败: $e');
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(
        title: l10n.t('feedback_title'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question about section
            Text(
              l10n.t('question_about'),
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
              children: _categories.isEmpty
                  ? _fallbackTags.map((tag) {
                      final value = tag.toLowerCase().replaceAll(' ', '_');
                      final isSelected = _selectedTags.contains(value);
                      return GestureDetector(
                        onTap: () => _toggleTag(value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.orange
                                : Colors.transparent,
                            border: Border.all(
                              color:
                                  isSelected ? AppColors.orange : Colors.grey,
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
                    }).toList()
                  : _categories.map((category) {
                      final value = category['value'] as String? ?? '';
                      final isSelected = _selectedTags.contains(value);
                      return GestureDetector(
                        onTap: () => _toggleTag(value),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.orange
                                : Colors.transparent,
                            border: Border.all(
                              color:
                                  isSelected ? AppColors.orange : Colors.grey,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            value,
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
            Row(
              children: [
                Text(
                  l10n.t('tell_more_info'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const Text(
                  '*',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ],
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
                  hintText: l10n.t('input_content'),
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
                    child: Text(
                      l10n.t('upload_logs_help'),
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
                onPressed: (_isSending ||
                        _selectedTags.isEmpty ||
                        _contentController.text.trim().isEmpty)
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
                    : Text(
                        l10n.t('send'),
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
