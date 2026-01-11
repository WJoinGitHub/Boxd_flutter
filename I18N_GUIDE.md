# 国际化使用说明

## 1. 已完成的配置

- ✅ 添加了 flutter_localizations 和 intl 依赖
- ✅ 创建了 AppLocalizations 类 (lib/l10n/app_localizations.dart)
- ✅ 在 main.dart 中配置了国际化支持
- ✅ 支持英文(en)和中文(zh)，默认英文，跟随系统语言

## 2. 如何在页面中使用

### 导入国际化类
```dart
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
```

### 在 Widget 中使用
```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  
  return Text(l10n.t('connected')); // 英文: "Connected", 中文: "已连接"
}
```

### 示例：替换硬编码文本
```dart
// 之前
Text('Connected')

// 之后
Text(AppLocalizations.of(context).t('connected'))

// 或者先获取实例
final l10n = AppLocalizations.of(context);
Text(l10n.t('connected'))
```

## 3. 已添加的翻译键值

### 通用
- cancel, confirm, save
- connected, connect_device
- power_on, power_off
- device_powered_on, device_powered_off
- failed_to_power_on, failed_to_power_off
- device_is_powered_off

### 设备相关
- edit_device_name, enter_device_name, device_name_saved
- edit_name, select_device

### 设置页面
- settings, support, help_and_troubleshooting
- device, my_device, unit_switching
- info, privacy_policy, terms_conditions
- app, feedback, allow_notifications
- logout, delete_account
- logout_confirm, delete_account_confirm

### 我的设备
- my_devices, no_devices, add_device
- unbind_device, unbind_device_confirm, unbind
- device_unbound_successfully, failed_to_load_devices

### 帮助页面
- help, help_intro, help_step1, help_step2
- help_power_off, help_power_on, help_trouble
- more_issues_faq, faq

## 4. 添加新的翻译

在 lib/l10n/app_localizations.dart 的 _localizedValues 中添加：

```dart
'en': {
  'your_new_key': 'English text',
  // ...
},
'zh': {
  'your_new_key': '中文文本',
  // ...
},
```

## 5. 下一步

需要在各个页面中将硬编码的文本替换为 `AppLocalizations.of(context).t('key')`

主要需要修改的文件：
- lib/pages/home_page.dart
- lib/pages/setting/setting_page.dart
- lib/pages/setting/my_devices_page.dart
- lib/pages/device/device_help_page.dart
- 其他包含用户可见文本的页面
