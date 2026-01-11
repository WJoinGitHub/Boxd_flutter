# FeedbackPage 和 DeviceConnectPage 国际化修改指南

## FeedbackPage 需要修改的内容

### 1. 添加导入
```dart
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
```

### 2. 在 build 方法开始添加
```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
```

### 3. 需要替换的文本
- 'Feedback' → l10n.t('feedback_title')
- 'Question about' → l10n.t('question_about')
- 'Tell me more information' → l10n.t('tell_more_info')
- 'input content' → l10n.t('input_content')
- 'Please select at least one question type' → l10n.t('select_question_type')
- 'Please enter feedback content' → l10n.t('enter_feedback_content')
- 'Feedback sent successfully' → l10n.t('feedback_submitted')
- 'Failed to send feedback' → l10n.t('feedback_failed')
- 'Send' → l10n.t('submit')
- 'Uploading logs helps us identify and fix the problem faster.' → l10n.t('upload_logs_help')

## DeviceConnectPage 需要修改的内容

### 1. 添加导入
```dart
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
```

### 2. 在 build 方法开始添加
```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
```

### 3. 需要替换的文本
- 'Connect Device' → l10n.t('connect_device_title')
- 'Auto-detecting' → l10n.t('auto_detecting')
- 'Please turn on Bluetooth' → l10n.t('turn_on_bluetooth')
- 'Scanning...' → l10n.t('scanning')
- 'Scan Devices' → l10n.t('scan_devices')
- 'Manually adding' → l10n.t('manually_adding')
- 'Unknown Device' → l10n.t('unknown_device')
- 'Help' → l10n.t('help')

## 需要添加到国际化文件的新键值

在 lib/l10n/app_localizations.dart 中添加：

```dart
'en': {
  // ... 现有键值
  'question_about': 'Question about',
  'tell_more_info': 'Tell me more information',
  'input_content': 'input content',
  'select_question_type': 'Please select at least one question type',
  'enter_feedback_content': 'Please enter feedback content',
  'upload_logs_help': 'Uploading logs helps us identify and fix the problem faster.',
  'auto_detecting': 'Auto-detecting',
  'turn_on_bluetooth': 'Please turn on Bluetooth',
  'scanning': 'Scanning...',
  'scan_devices': 'Scan Devices',
  'manually_adding': 'Manually adding',
  'unknown_device': 'Unknown Device',
},
'zh': {
  // ... 现有键值
  'question_about': '问题类型',
  'tell_more_info': '告诉我更多信息',
  'input_content': '输入内容',
  'select_question_type': '请至少选择一个问题类型',
  'enter_feedback_content': '请输入反馈内容',
  'upload_logs_help': '上传日志可以帮助我们更快地识别和修复问题。',
  'auto_detecting': '自动检测中',
  'turn_on_bluetooth': '请打开蓝牙',
  'scanning': '扫描中...',
  'scan_devices': '扫描设备',
  'manually_adding': '添加设备',
  'unknown_device': '未知设备',
},
```

## 快速应用步骤

1. 先在 lib/l10n/app_localizations.dart 中添加所有新的翻译键值
2. 在 FeedbackPage 和 DeviceConnectPage 文件顶部添加导入
3. 在各自的 build 方法开始处添加 `final l10n = AppLocalizations.of(context);`
4. 使用查找替换功能批量替换硬编码文本为 `l10n.t('key')`

由于这两个文件较大且包含较多文本，建议使用 IDE 的查找替换功能进行批量修改。
