import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/utils/bx_app_bar.dart';

/// FAQ详情页面
class FaqDetailPage extends StatelessWidget {
  final String questionKey; // 问题的国际化key

  const FaqDetailPage({
    super.key,
    required this.questionKey,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 根据questionKey获取标题和内容
    final title = _getTitle(l10n, questionKey);
    final contents = _getContents(l10n, questionKey);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: BxAppBar(title: ""),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 60),
            // 内容段落
            ...contents.map((content) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                      height: 1.5,
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _getTitle(AppLocalizations l10n, String key) {
    switch (key) {
      case 'app_issues_or_crashes':
        return l10n.t('app_issues_or_crashes_title');
      case 'heating_not_working':
        return l10n.t('heating_not_working_title');
      case 'device_connection_failed':
        return l10n.t('device_connection_failed_title');
      case 'device_not_found_scan':
        return l10n.t('device_not_found_scan_title');
      case 'use_device_without_account':
        return l10n.t('use_device_without_account_title');
      case 'device_connected_not_responding':
        return l10n.t('device_connected_not_responding_title');
      case 'scheduled_heating_issues':
        return l10n.t('scheduled_heating_issues_title');
      case 'bluetooth_connection_issues':
        return l10n.t('bluetooth_connection_issues_title');
      default:
        return '';
    }
  }

  List<String> _getContents(AppLocalizations l10n, String key) {
    switch (key) {
      case 'app_issues_or_crashes':
        return [
          l10n.t('app_issues_or_crashes_content_1'),
          l10n.t('app_issues_or_crashes_content_2'),
        ];
      case 'heating_not_working':
        return [
          l10n.t('heating_not_working_content_1'),
          l10n.t('heating_not_working_content_2'),
        ];
      case 'device_connection_failed':
        return [
          l10n.t('device_connection_failed_content_1'),
          l10n.t('device_connection_failed_content_2'),
          l10n.t('device_connection_failed_content_3'),
        ];
      case 'device_not_found_scan':
        return [
          l10n.t('device_not_found_scan_content_1'),
          l10n.t('device_not_found_scan_content_2'),
        ];
      case 'use_device_without_account':
        return [
          l10n.t('use_device_without_account_content_1'),
          l10n.t('use_device_without_account_content_2'),
        ];
      case 'device_connected_not_responding':
        return [
          l10n.t('device_connected_not_responding_content_1'),
          l10n.t('device_connected_not_responding_content_2'),
          l10n.t('device_connected_not_responding_content_3'),
        ];
      case 'scheduled_heating_issues':
        return [
          l10n.t('scheduled_heating_issues_content_1'),
          l10n.t('scheduled_heating_issues_content_2'),
        ];
      case 'bluetooth_connection_issues':
        return [
          l10n.t('bluetooth_connection_issues_content_1'),
          l10n.t('bluetooth_connection_issues_content_2'),
        ];
      default:
        return [];
    }
  }
}
