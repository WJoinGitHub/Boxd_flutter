# HomePage 国际化修改指南

## 需要在 home_page.dart 文件顶部添加导入：

```dart
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
```

## 在 build 方法开始处添加：

```dart
@override
Widget build(BuildContext context) {
  final l10n = AppLocalizations.of(context);  // 添加这一行
  return Scaffold(
```

## 需要替换的文本（按行号顺序）：

### 1. 第 367 行 - 编辑设备名对话框
```dart
// 修改前
title: const Text('Edit Device Name'),
content: TextField(
  controller: controller,
  decoration: const InputDecoration(
    hintText: 'Enter device name',
  ),
  autofocus: true,
),
actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('Cancel'),
  ),
  TextButton(
    onPressed: () => Navigator.pop(context, controller.text.trim()),
    child: const Text('Save'),
  ),
],

// 修改后
title: Text(l10n.t('edit_device_name')),
content: TextField(
  controller: controller,
  decoration: InputDecoration(
    hintText: l10n.t('enter_device_name'),
  ),
  autofocus: true,
),
actions: [
  TextButton(
    onPressed: () => Navigator.pop(context),
    child: Text(l10n.t('cancel')),
  ),
  TextButton(
    onPressed: () => Navigator.pop(context, controller.text.trim()),
    child: Text(l10n.t('save')),
  ),
],
```

### 2. 第 391 行 - 设备名称保存提示
```dart
// 修改前
const SnackBar(content: Text('Device name saved'))

// 修改后
SnackBar(content: Text(l10n.t('device_name_saved')))
```

### 3. 第 413 行 - 选择设备标题
```dart
// 修改前
const Padding(
  padding: EdgeInsets.symmetric(vertical: 16),
  child: Text(
    'Select Device',

// 修改后
Padding(
  padding: const EdgeInsets.symmetric(vertical: 16),
  child: Text(
    l10n.t('select_device'),
```

### 4. 第 425 行 - 已连接文本
```dart
// 修改前
'Connected',

// 修改后
l10n.t('connected'),
```

### 5. 第 520 行 - 连接设备文本
```dart
// 修改前
'Connect Device',

// 修改后
l10n.t('connect_device'),
```

### 6. 第 565 行 - 设备未找到提示
```dart
// 修改前
const SnackBar(
    content: Text(
        'Device not found. Please make sure the device is powered on and nearby.'))

// 修改后
SnackBar(content: Text(l10n.t('device_not_found')))
```

### 7. 第 571 行 - 连接失败提示
```dart
// 修改前
SnackBar(content: Text('Failed to connect device: $e'))

// 修改后
SnackBar(content: Text('${l10n.t('failed_to_connect')}: $e'))
```

### 8. 第 794-795 行 - 连接状态文本
```dart
// 修改前
connected
    ? "Connected"
    : "Connect your Lunch box",

// 修改后
connected
    ? l10n.t('connected')
    : l10n.t('connect_your_lunch_box'),
```

### 9. 第 920 行 - 设备工作结束时间
```dart
// 修改前
'Device work ends at ${_getEndTimeText()}',

// 修改后
'${l10n.t('device_work_ends_at')} ${_getEndTimeText()}',
```

### 10. 第 1025-1033 行 - 开机提示
```dart
// 修改前
const SnackBar(content: Text('Device powered on'))
const SnackBar(content: Text('Failed to power on, please try again'))

// 修改后
SnackBar(content: Text(l10n.t('device_powered_on')))
SnackBar(content: Text(l10n.t('failed_to_power_on')))
```

### 11. 第 1039-1047 行 - 关机提示
```dart
// 修改前
const SnackBar(content: Text('Device powered off'))
const SnackBar(content: Text('Failed to power off, please try again'))

// 修改后
SnackBar(content: Text(l10n.t('device_powered_off')))
SnackBar(content: Text(l10n.t('failed_to_power_off')))
```

### 12. 第 1061 行 - 电源按钮文本
```dart
// 修改前
_isPoweredOff ? 'POWER ON' : 'POWER OFF',

// 修改后
_isPoweredOff ? l10n.t('power_on') : l10n.t('power_off'),
```

### 13. 第 1177 行 - 设备已关机提示
```dart
// 修改前
const SnackBar(content: Text('Device is powered off'))

// 修改后
SnackBar(content: Text(l10n.t('device_is_powered_off')))
```

## 快速应用方法

由于修改较多，建议使用 IDE 的查找替换功能：

1. 在文件顶部添加导入
2. 在 build 方法开始添加 `final l10n = AppLocalizations.of(context);`
3. 使用查找替换功能批量替换上述文本

或者直接运行以下命令查看所有需要修改的位置：
```bash
grep -n "Connected\|Connect Device\|POWER ON\|POWER OFF\|Device powered\|Edit Device Name\|Enter device name\|Device name saved\|Select Device\|Device not found\|Failed to connect\|Device is powered off\|Device work ends at" lib/pages/home_page.dart
```
