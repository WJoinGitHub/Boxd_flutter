import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/pages/setting/feedback_page.dart';
import 'package:url_launcher/url_launcher.dart';

class FaqPage extends StatelessWidget {
  const FaqPage({super.key});

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
            _buildCategoryCards(l10n),
            const SizedBox(height: 30),

            // Top Questions 部分
            _buildTopQuestions(context, l10n),
            const SizedBox(height: 30),

            // Contact Service 部分
            _buildContactService(l10n),
            const SizedBox(height: 30),

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
  Widget _buildCategoryCards(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildCategoryCard(
              icon: Icons.notifications_outlined,
              iconColor: Colors.blue,
              backgroundColor: Colors.blue[50]!,
              title: 'Questions about',
              subtitle: 'Getting Started',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCategoryCard(
              icon: Icons.bluetooth_connected,
              iconColor: Colors.green,
              backgroundColor: Colors.green[50]!,
              title: 'Questions about',
              subtitle: 'How to Connect',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildCategoryCard(
              icon: Icons.help_outline,
              iconColor: Colors.purple,
              backgroundColor: Colors.purple[50]!,
              title: 'Questions about',
              subtitle: 'How to Use',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
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
    );
  }

  /// Top Questions 部分
  Widget _buildTopQuestions(BuildContext context, AppLocalizations l10n) {
    final topQuestions = [
      'Not scanned my equipment',
      'Ai message how to work',
      'Device connect failed',
      'Device connect failed',
      'Device connect failed',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () {
                  // TODO: 跳转到所有问题页面
                },
                child: const Text(
                  'View all',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topQuestions.map((question) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildQuestionItem(question),
              )),
        ],
      ),
    );
  }

  Widget _buildQuestionItem(String question) {
    return Container(
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
    final email = 'support@qimitech.com';
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.t('email_address_copied').replaceAll('{email}', email)),
        duration: const Duration(seconds: 2),
      ),
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
