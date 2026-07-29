import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/app_toast.dart';
import 'package:flutter_boxd_app_flow/pages/setting/feedback_page.dart';
import 'package:flutter_boxd_app_flow/pages/device/faq_detail_page.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  /// 本地兜底邮箱（接口无 brand_email 时使用）
  static const String _fallbackSupportEmail = 'support@qimitech.com';

  String _supportEmail = _fallbackSupportEmail;
  /// 邮箱接口已返回（成功或失败）后再展示联系邮箱入口
  bool _brandEmailReady = false;

  @override
  void initState() {
    super.initState();
    _loadBrandEmail();
  }

  Future<void> _loadBrandEmail() async {
    try {
      final result = await ApiClient.getFeedbackBrand();
      print('[FAQ] 品牌信息接口返回: $result');
      if (result['code'] == 200 && result['data'] is Map) {
        final email =
            (result['data'] as Map)['brand_email']?.toString().trim();
        if (email != null && email.isNotEmpty) {
          _supportEmail = email;
        }
      }
    } catch (e) {
      print('[FAQ] 获取品牌邮箱失败，使用本地兜底: $e');
    } finally {
      if (mounted) {
        setState(() => _brandEmailReady = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(title: l10n.t('help')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /*
            // 视频播放器占位符
            _buildVideoPlaceholder(),
            const SizedBox(height: 20),*/

            // 分类卡片
            _buildCategoryCards(context, l10n),
            const SizedBox(height: 30),

            // Top Questions 部分
            _buildTopQuestions(context, l10n),
            const SizedBox(height: 30),

            // Contact Service：等邮箱接口返回后再显示（失败也显示兜底邮箱）
            if (_brandEmailReady) ...[
              _buildContactService(l10n),
              const SizedBox(height: 30),
            ],

            // Feedback 按钮
            _buildFeedbackButton(context, l10n),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 视频播放器占位符
  Widget _buildVideoPlaceholder() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.play_arrow,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }

  /// 分类卡片
  Widget _buildCategoryCards(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 100, // 固定高度，确保三个卡片高度一致
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            SizedBox(
              width: 150,
              child: _buildCategoryCard(
                number: '1',
                backgroundColor: Colors.blue[50]!,
                title: l10n.t('device_connect'),
                subtitle: l10n.t('not_found'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FaqDetailPage(
                          questionKey: 'device_not_found_scan'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 150,
              child: _buildCategoryCard(
                number: '2',
                backgroundColor: Colors.green[50]!,
                title: l10n.t('device_connect'),
                subtitle: l10n.t('connect_failed'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FaqDetailPage(
                          questionKey: 'device_connection_failed'),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 150,
              child: _buildCategoryCard(
                number: '3',
                backgroundColor: Colors.grey[100]!,
                title: l10n.t('device_work'),
                subtitle: l10n.t('not_working'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const FaqDetailPage(
                          questionKey: 'heating_not_working'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard({
    required String number,
    required Color backgroundColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120, // 固定高度，确保三个卡片高度一致
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Top Questions 部分
  Widget _buildTopQuestions(BuildContext context, AppLocalizations l10n) {
    // 定义5个常见问题和对应的详情页面key
    final topQuestions = [
      {
        'text': l10n.t('bluetooth_connection_issues'),
        'key': 'bluetooth_connection_issues'
      },
      {
        'text': l10n.t('scheduled_heating_issues'),
        'key': 'scheduled_heating_issues'
      },
      {
        'text': l10n.t('device_connected_not_responding'),
        'key': 'device_connected_not_responding'
      },
      {'text': l10n.t('app_issues_or_crashes'), 'key': 'app_issues_or_crashes'},
      {
        'text': l10n.t('can_use_device_without_account'),
        'key': 'use_device_without_account'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('top_questions'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...topQuestions.map((question) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildQuestionItem(
                  context,
                  question['text']!,
                  question['key']!,
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(
      BuildContext context, String question, String questionKey) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FaqDetailPage(questionKey: questionKey),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Contact Service 部分
  Widget _buildContactService(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.t('contact_service'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Builder(
                builder: (context) => _buildContactItem(
                  icon: Icons.email_outlined,
                  label: l10n.t('email'),
                  onTap: () => _openEmailApp(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 打开系统邮箱应用发送邮件
  Future<void> _openEmailApp(BuildContext context) async {
    final email = _supportEmail.trim().isNotEmpty
        ? _supportEmail.trim()
        : _fallbackSupportEmail;
    final uri = Uri.parse('mailto:$email');
    try {
      // 尝试打开邮箱应用，使用 externalApplication 模式
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showEmailFallback(context, email);
      }
    } catch (e) {
      print('打开邮箱应用失败: $e');
      // 如果失败，尝试使用 platformDefault 模式
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
        if (!launched) {
          _showEmailFallback(context, email);
        }
      } catch (e2) {
        print('使用 platformDefault 模式也失败: $e2');
        _showEmailFallback(context, email);
      }
    }
  }

  /// 备用方案：复制邮箱地址到剪贴板并提示用户
  void _showEmailFallback(BuildContext context, String email) {
    Clipboard.setData(ClipboardData(text: email));
    final l10n = AppLocalizations.of(context);
    AppToast.show(
      context,
      l10n.t('email_address_copied').replaceAll('{email}', email),
      duration: const Duration(seconds: 2),
    );
  }

  /// Feedback 按钮
  Widget _buildFeedbackButton(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FeedbackPage(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            l10n.t('feedback'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
