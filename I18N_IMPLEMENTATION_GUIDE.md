# 国际化应用完整指南

## 已完成的配置

✅ 完整的国际化翻译文件已创建 (lib/l10n/app_localizations.dart)
✅ 包含所有页面的翻译键值（英文和中文）
✅ main.dart 已配置国际化支持

## 已完成国际化的页面

1. ✅ DeviceHelpPage
2. ✅ SettingsPage  
3. ✅ MyDevicesPage

## 需要应用国际化的页面

### 在每个页面中应用国际化的步骤：

1. **导入国际化类**
```dart
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
```

2. **在 build 方法中获取实例**
```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  // ...
}
```

3. **替换硬编码文本**
```dart
// 之前
Text('Connect Device')

// 之后
Text(l10n.t('connect_device'))
```

## 各页面需要替换的文本示例

### HomePage (home_page.dart)
- 'Connected' → l10n.t('connected')
- 'Connect your Lunch box' → l10n.t('connect_your_lunch_box')
- 'Connect Device' → l10n.t('connect_device')
- 'POWER ON' → l10n.t('power_on')
- 'POWER OFF' → l10n.t('power_off')
- 'Device powered on' → l10n.t('device_powered_on')
- 'Device powered off' → l10n.t('device_powered_off')
- 'Device is powered off' → l10n.t('device_is_powered_off')
- 'Edit Device Name' → l10n.t('edit_device_name')
- 'Enter device name' → l10n.t('enter_device_name')
- 'Device name saved' → l10n.t('device_name_saved')
- 'Select Device' → l10n.t('select_device')
- 'Cancel' → l10n.t('cancel')
- 'Save' → l10n.t('save')

### KeepWarmPage (keep_warm_page.dart)
- 'Keep Warm' → l10n.t('keep_warm_title')
- 'Set Temperature' → l10n.t('set_temperature')
- 'Start' → l10n.t('start')
- 'Stop' → l10n.t('stop')

### HeatPage (heat_page.dart)
- 'Heat' → l10n.t('heat_title')
- 'Heating Time' → l10n.t('heating_time')
- 'Minutes' → l10n.t('minutes')
- 'Start' → l10n.t('start')

### HeatingTimePage (heating_time_page.dart)
- 'Heating Time' → l10n.t('heating_time_title')
- 'Set Meal Time' → l10n.t('set_meal_time')
- 'Meal Time' → l10n.t('meal_time')
- 'Start' → l10n.t('start')

### DeviceConnectPage (device/device_connect_page.dart)
- 'Connect Device' → l10n.t('connect_device_title')
- 'Searching for devices...' → l10n.t('searching_devices')
- 'No devices found' → l10n.t('no_devices_found')
- 'Connecting...' → l10n.t('connecting')
- 'Connection failed' → l10n.t('connection_failed')
- 'Connection successful' → l10n.t('connection_success')

### EmailLoginPage (login/email_login_page.dart)
- 'Login' → l10n.t('login')
- 'Email' → l10n.t('email')
- 'Password' → l10n.t('password')
- 'Enter your email' → l10n.t('enter_email')
- 'Enter your password' → l10n.t('enter_password')
- 'Sign In' → l10n.t('sign_in')
- "Don't have an account?" → l10n.t('dont_have_account')
- 'Sign Up' → l10n.t('sign_up')

### RegisterEmailPage (login/register_email_page.dart)
- 'Register' → l10n.t('register')
- 'Email' → l10n.t('email')
- 'Enter your email' → l10n.t('enter_email')
- 'Next' → l10n.t('next')
- 'Already have an account?' → l10n.t('already_have_account')
- 'Sign In' → l10n.t('sign_in')

### FeedbackPage (setting/feedback_page.dart)
- 'Feedback' → l10n.t('feedback_title')
- 'Please enter your feedback' → l10n.t('feedback_hint')
- 'Submit' → l10n.t('submit')
- 'Feedback submitted successfully' → l10n.t('feedback_submitted')

### UnitSwitchingPage (setting/unit_switching_page.dart)
- 'Unit Switching' → l10n.t('unit_switching_title')
- 'Temperature Unit' → l10n.t('temperature_unit')
- 'Celsius (°C)' → l10n.t('celsius')
- 'Fahrenheit (°F)' → l10n.t('fahrenheit')

## 完整示例

### 示例 1: 简单文本替换
```dart
// 之前
Text('Connect Device')

// 之后
final l10n = AppLocalizations.of(context);
Text(l10n.t('connect_device'))
```

### 示例 2: 对话框
```dart
// 之前
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Logout'),
    content: Text('Are you sure you want to logout?'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancel'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('Confirm'),
      ),
    ],
  ),
);

// 之后
final l10n = AppLocalizations.of(context);
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(l10n.t('logout')),
    content: Text(l10n.t('logout_confirm')),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(l10n.t('cancel')),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text(l10n.t('confirm')),
      ),
    ],
  ),
);
```

### 示例 3: SnackBar
```dart
// 之前
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Device powered on')),
);

// 之后
final l10n = AppLocalizations.of(context);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(l10n.t('device_powered_on'))),
);
```

## 所有可用的翻译键

查看 lib/l10n/app_localizations.dart 文件中的 _localizedValues 映射，包含所有可用的翻译键。

## 测试国际化

1. **测试英文**：设备语言设置为英文
2. **测试中文**：设备语言设置为中文
3. 应用会自动跟随系统语言，默认为英文

## 添加新的翻译

如需添加新的翻译键值，在 lib/l10n/app_localizations.dart 中添加：

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
