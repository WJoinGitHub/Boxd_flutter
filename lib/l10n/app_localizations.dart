import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'ok': 'OK',
      'next': 'Next',
      'back': 'Back',
      'done': 'Done',
      'skip': 'Skip',

      // Home Page
      'connected': 'Connected',
      'connect_your_lunch_box': 'Connect your Lunch box',
      'connect_device': 'Connect Device',
      'connect_device_countdown': 'Connect Device {seconds}s',
      'homepage_slogan': 'Explore, Make the Future More Possible',
      'keep_warm': 'Keep\nWarm',
      'heat': 'Heat',
      'timer': 'Timer',
      'ins': 'Keep Warm',
      'device_work_ends_at': 'Device work ends at',
      'time_left': 'Time Left',
      'power_on': 'POWER ON',
      'power_off': 'POWER OFF',
      'device_powered_on': 'Device powered on',
      'device_powered_off': 'Device powered off',
      'failed_to_power_on': 'Failed to power on, please try again',
      'failed_to_power_off': 'Failed to power off, please try again',
      'device_is_powered_off': 'Device is powered off',
      'edit_device_name': 'Edit Device Name',
      'enter_device_name': 'Enter device name',
      'device_name_saved': 'Device name saved',
      'edit_nickname': 'Edit Nickname',
      'enter_nickname': 'Enter nickname',
      'nickname_updated_successfully': 'Nickname updated successfully',
      'update_failed': 'Update failed',
      'edit_name': 'Edit Name',
      'select_device': 'Select Device',
      'device_not_found':
          'Device not found. Please make sure the device is powered on and nearby.',
      'failed_to_connect': 'Failed to connect device',

      // Settings
      'settings': 'Settings',
      'support': 'Support',
      'help_and_troubleshooting': 'Help and Troubleshooting',
      'device': 'Device',
      'my_device': 'My Device',
      'unit_switching': 'Unit switching',
      'info': 'Info',
      'privacy_policy': 'Privacy Policy',
      'terms_conditions': 'Terms & Conditions',
      'app': 'App',
      'feedback': 'Feedback',
      'allow_notifications': 'Allow Notifications',
      'logout': 'Logout',
      'delete_account': 'Delete Account',
      'logout_confirm': 'Are you sure you want to logout?',
      'delete_account_confirm':
          'Are you sure you want to delete your account? This action cannot be undone!',
      'logout_failed': 'Logout failed',
      'delete_account_failed': 'Delete account failed',

      // My Devices
      'my_devices': 'My Devices',
      'no_devices': 'No devices',
      'add_device': 'Add Device',
      'unbind_device': 'Unbind Device',
      'unbind_device_confirm': 'Are you sure you want to unbind',
      'unbind': 'Unbind',
      'device_unbound_successfully': 'Device unbound successfully',
      'failed_to_unbind_device': 'Failed to unbind device',
      'failed_to_load_devices': 'Failed to load devices',

      // Help Page
      'help': 'Help',
      'help_intro':
          "No worries, I'm here to help. Let's work through this together. Please try the following:",
      'help_step1': '1. Could you check if your device has Bluetooth?',
      'help_step2':
          '2. Connection issue? A simple restart of your device often helps. Then try to connect again.',
      'help_power_off': 'Press and hold the power button to shut down.',
      'help_power_on': 'Press the power button again to turn it back on.',
      'help_trouble':
          'Have trouble? A Quick Guide to Fixing Your [Device Name] Connection Issues.',
      'more_issues_faq': 'More issues. Please check the  FAQ',
      'faq': 'FAQ',
      'contact_service': 'Contact Service',
      'email': 'Email',

      // Keep Warm Page
      'keep_warm_title': 'Keep Warm',
      'keep_warm_mode': 'Keep Warm',
      'set_temperature': 'Set Temperature',
      'start': 'Start',
      'stop': 'Stop',

      // Heat Page
      'heat_title': 'Heat',
      'heating_mode': 'Heating',
      'heating_time': 'Heating Time',
      'minutes': 'Minutes',
      'min_abbreviation': 'MIN',
      'hours_abbreviation': 'HOURS',

      // Heating Time Page
      'heating_time_title': 'Heating Time',
      'timer_mode': 'Timer',
      'set_meal_time': 'Set Meal Time',
      'meal_time': 'Meal Time',

      // Device Connect Page
      'connect_device_title': 'Connect Device',
      'searching_devices': 'Searching for devices...',
      'no_devices_found': 'No devices found',
      'nearby_devices': 'Nearby devices...',
      'turn_on_bluetooth': 'Please turn on Bluetooth',
      'connecting': 'Connecting...',
      'connection_failed': 'Connection failed',
      'connection_success': 'Connection successful',

      // Login Pages
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'username': 'Username',
      'enter_email': 'Enter your email',
      'enter_password': 'Enter your password',
      'enter_username': 'Enter your username',
      'forgot_password': 'Forgot Password?',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'sign_up_for': 'Sign up for HeatLink',
      'create_a_profile': 'Create a profile, manage your device',
      'guest_mode': 'Guest mode',
      'email_login': 'Email Login',
      'facebook_login': 'Facebook Login',
      'google_login': 'Google Login',
      'apple_login': 'Apple Login',
      'or_continue_with': 'Or continue with',
      'google': 'Google',
      'apple': 'Apple',
      'facebook': 'Facebook',
      'verification_code': 'Verification Code',
      'enter_verification_code': 'Enter verification code',
      'resend_code': 'Resend Code',
      'verify': 'Verify',
      'set_password': 'Set Password',
      'confirm_password': 'Confirm Password',
      'password_requirements': 'Password must be at least 8 characters',
      'passwords_dont_match': 'Passwords do not match',
      'invalid_email': 'Invalid email address',
      'invalid_email_message': 'Please enter a valid email address',
      'email_already_exists': 'Email already exists',
      'login_failed': 'Login failed',
      'login_success': 'Login successful!',
      'guest_login': 'Guest Login',
      'guest_login_success': 'Guest login successful!',
      'guest_login_failed': 'Guest login failed',
      'registration_failed': 'Registration failed',
      'registration_success': 'Registration successful!',
      'reset_password': 'Reset Password',
      'create_password': 'Create Password',
      'password_reset_success': 'Password reset successful',
      'reset_failed': 'Reset failed',
      'please_enter_six_or_more_characters':
          'Please enter six or more characters',
      'enter_six_or_more_characters': 'Enter six or more characters',
      'eight_to_twenty_characters': '8 to 20 characters',
      'letters_numbers_special_characters':
          'Letters, number, and special characters',
      'password_requirements_detail':
          'Password requirements: 8-20 characters, containing letters and numbers',
      'username_label': 'UserName',
      'terms_of_service': 'Terms of Service',
      'privacy_policy': 'Privacy Policy',
      'agree_to_terms_prefix': 'By continuing, you agree to HeatLink\'s ',
      'agree_to_terms_middle': ' and confirm that you have read HeatLink\'s ',
      'agree_to_terms_suffix':
          ' to learn how we collect, use, and share your data.',
      'please_enter_code_sent_to_email':
          'Please enter the 4-digit code sent to your email ',
      'for_verification': ' for verification.',
      'request_new_code_in': 'Request new code in ',
      'seconds': 's',
      'send_again': 'Send again',
      'verification_failed': 'Verification failed',
      'send_failed': 'Send failed',
      'request_error': 'Request error',
      'verify_button': 'VERIFY',

      // Feedback Page
      'feedback_title': 'Feedback',
      'feedback_hint': 'Please enter your feedback',
      'submit': 'Submit',
      'feedback_submitted': 'Feedback submitted successfully',
      'feedback_failed': 'Failed to submit feedback',
      'failed_to_send_feedback': 'Failed to send feedback',

      // Feedback Page
      'question_about': 'Question about',
      'tell_more_info': 'Tell me more information',
      'input_content': 'input content',
      'select_question_type': 'Please select at least one question type',
      'enter_feedback_content': 'Please enter feedback content',
      'upload_logs_help':
          'Uploading logs helps us identify and fix the problem faster.',
      'send': 'Send',
      'retry': 'Retry',
      'device_trouble_msg':
          'Having trouble finding your device. Is it turned on? or Manually add.Or click on ',
      'device_trouble_suffix': ' to troubleshoot andresolve',

      // Device Connect Page
      'auto_detecting': 'Auto-detecting',
      'turn_on_bluetooth': 'Please turn on Bluetooth',
      'scanning': 'Scanning...',
      'scan_devices': 'Scan Devices',
      'manually_adding': 'Manually adding',
      'unknown_device': 'Unknown Device',

      // Unit Switching Page
      'unit_switching_title': 'Unit Switching',
      'temperature_unit': 'Temperature Unit',
      'celsius': 'Celsius (°C)',
      'fahrenheit': 'Fahrenheit (°F)',

      // Meal Time Page
      'meal_time_title': 'Meal Time',
      'select_time': 'Select Time',
      'hour': 'Hour',
      'minute': 'Minute',
      'select_duration': 'Select Duration',
      'select_end_time': 'Select End Time',
      'warming_duration': 'Warming Duration',
      'hours': 'Hours',
      'setting_heat_duration': 'Setting Heat Duration',
      'setting_temperature': 'Setting Temperature',
      'setting_end_time': 'Setting end time',
      'remind': 'Remind',
      'device_not_connected':
          'Device not connected. Please connect your device first.',
      'keep_warm_started': 'Keep warm started successfully',
      'keep_warm_stopped': 'Keep warm stopped successfully',
      'heat_started': 'Heat started successfully',
      'heat_stopped': 'Heat stopped successfully',
      'heat_started_but_reminder_failed':
          'Heat started, but reminder setup failed',
      'timing_heating_started': 'Timing heating started successfully',
      'timing_heating_stopped': 'Timing heating stopped successfully',
      'command_failed': 'Failed to send command. Please try again.',
      'please_select_temperature': 'Please select temperature',
      'heating_time_range': 'Heating time must be between 20-50 minutes',
      'heating_time_exceed': 'Heating time cannot exceed 5 hours',
      'end_time_exceed': 'End time cannot exceed 5 hours from now',
      'end_time_past': 'End time cannot be earlier than current time',
      'heating_duration_too_long':
          'Heating duration too long, cannot finish before set time',

      // Calendar
      'calendar_permission_denied': 'Calendar permission denied',
      'calendar_permission_denied_detail':
          'Calendar permission denied. Please enable it in settings to use reminder feature.',
      'failed_to_access_calendar': 'Failed to access calendar',
      'failed_to_retrieve_calendars': 'Failed to retrieve calendars',
      'no_calendars_available': 'No calendars available',
      'event_saved_to_calendar': 'Event saved to calendar',
      'saved_to_calendar': 'Saved to calendar',
      'calendar_reminder_created_successfully':
          'Calendar reminder created successfully',
      'failed_to_save_to_calendar': 'Failed to save to calendar',
      'error': 'Error',

      // Unit Switching
      'unit_switching_description':
          'You can set the display unit for temperature here',
      'fahrenheit': 'Fahrenheit',
      'centigrade': 'Centigrade',
      'temperature_unit_changed_to': 'Temperature unit changed to',
      'failed_to_send_command_try_again':
          'Failed to send command, please try again',
      'unknown_error': 'Unknown error',
    },
    'zh': {
      // Common
      'cancel': '取消',
      'confirm': '确认',
      'save': '保存',
      'delete': '删除',
      'edit': '编辑',
      'ok': '确定',
      'next': '下一步',
      'back': '返回',
      'done': '完成',
      'skip': '跳过',

      // Home Page
      'connected': '已连接',
      'connect_your_lunch_box': '连接你的饭盒',
      'connect_device': '连接设备',
      'connect_device_countdown': '连接设备 {seconds}s',
      'homepage_slogan': '探索，让未来更美好',
      'keep_warm': '保温',
      'heat': '加热',
      'timer': '定时',
      'ins': '保温',
      'device_work_ends_at': '设备工作结束时间',
      'time_left': '剩余时间',
      'power_on': '开机',
      'power_off': '关机',
      'device_powered_on': '设备已开机',
      'device_powered_off': '设备已关机',
      'failed_to_power_on': '开机失败，请重试',
      'failed_to_power_off': '关机失败，请重试',
      'device_is_powered_off': '设备已关机',
      'edit_device_name': '编辑设备名称',
      'enter_device_name': '输入设备名称',
      'device_name_saved': '设备名称已保存',
      'edit_nickname': '编辑昵称',
      'enter_nickname': '输入昵称',
      'nickname_updated_successfully': '昵称更新成功',
      'update_failed': '更新失败',
      'edit_name': '编辑名称',
      'select_device': '选择设备',
      'device_not_found': '未找到设备。请确保设备已开机并在附近。',
      'failed_to_connect': '连接设备失败',

      // Settings
      'settings': '设置',
      'support': '支持',
      'help_and_troubleshooting': '帮助和故障排除',
      'device': '设备',
      'my_device': '我的设备',
      'unit_switching': '单位切换',
      'info': '信息',
      'privacy_policy': '隐私政策',
      'terms_conditions': '条款和条件',
      'app': '应用',
      'feedback': '反馈',
      'allow_notifications': '通知',
      'logout': '退出登录',
      'delete_account': '删除账号',
      'logout_confirm': '确定要退出登录吗？',
      'delete_account_confirm': '确定要删除账号吗？此操作无法撤销！',
      'logout_failed': '退出登录失败',
      'delete_account_failed': '删除账号失败',

      // My Devices
      'my_devices': '我的设备',
      'no_devices': '暂无设备',
      'add_device': '添加设备',
      'unbind_device': '解绑设备',
      'unbind_device_confirm': '确定要解绑',
      'unbind': '解绑',
      'device_unbound_successfully': '设备解绑成功',
      'failed_to_unbind_device': '设备解绑失败',
      'failed_to_load_devices': '加载设备列表失败',

      // Help Page
      'help': '帮助',
      'help_intro': '别担心，我来帮你。让我们一起解决这个问题。请尝试以下操作：',
      'help_step1': '1. 请检查您的设备是否有蓝牙？',
      'help_step2': '2. 连接问题？简单重启设备通常会有帮助。然后再次尝试连接。',
      'help_power_off': '长按电源键关机。',
      'help_power_on': '再次按下电源键开机。',
      'help_trouble': '遇到问题？快速指南帮您解决[设备名称]连接问题。',
      'more_issues_faq': '更多问题，请查看常见问题',
      'faq': '常见问题',
      'contact_service': '联系客服',
      'email': '邮箱',

      // Keep Warm Page
      'keep_warm_title': '保温',
      'keep_warm_mode': '保温模式',
      'set_temperature': '设置温度',
      'start': '开始',
      'stop': '停止',

      // Heat Page
      'heat_title': '加热',
      'heating_mode': '加热模式',
      'heating_time': '加热时间',
      'minutes': '分钟',
      'min_abbreviation': '分钟',
      'hours_abbreviation': '小时',

      // Heating Time Page
      'heating_time_title': '定时加热',
      'timer_mode': '定时加热模式',
      'set_meal_time': '设置用餐时间',
      'meal_time': '用餐时间',

      // Device Connect Page
      'connect_device_title': '连接设备',
      'searching_devices': '正在搜索设备...',
      'no_devices_found': '未找到设备',
      'nearby_devices': '附近设备...',
      'turn_on_bluetooth': '请打开蓝牙',
      'connecting': '连接中...',
      'connection_failed': '连接失败',
      'connection_success': '连接成功',

      // Login Pages
      'login': '登录',
      'register': '注册',
      'email': '邮箱',
      'password': '密码',
      'username': '用户名',
      'enter_email': '输入您的邮箱',
      'enter_password': '输入您的密码',
      'enter_username': '输入您的用户名',
      'forgot_password': '忘记密码？',
      'dont_have_account': '还没有账号？',
      'already_have_account': '已有账号？',
      'sign_in': '登录',
      'sign_up': '注册',
      'sign_up_for': '注册 HeatLink',
      'create_a_profile': '创建个人资料，管理您的设备',
      'guest_mode': '游客模式',
      'or_continue_with': '或继续使用',
      'google': '谷歌',
      'apple': '苹果',
      'facebook': '脸书',
      'verification_code': '验证码',
      'enter_verification_code': '输入验证码',
      'resend_code': '重新发送',
      'verify': '验证',
      'set_password': '设置密码',
      'confirm_password': '确认密码',
      'password_requirements': '密码至少需要8个字符',
      'passwords_dont_match': '密码不匹配',
      'invalid_email': '邮箱地址无效',
      'invalid_email_message': '请输入有效的邮箱地址',
      'email_already_exists': '邮箱已存在',
      'login_failed': '登录失败',
      'login_success': '登录成功！',
      'guest_login': '游客登录',
      'guest_login_success': '游客登录成功！',
      'guest_login_failed': '游客登录失败',
      'registration_failed': '注册失败',
      'registration_success': '注册成功！',
      'reset_password': '重置密码',
      'create_password': '创建密码',
      'password_reset_success': '密码重置成功',
      'reset_failed': '重置失败',
      'please_enter_six_or_more_characters': '请输入六个或更多字符',
      'enter_six_or_more_characters': '输入六个或更多字符',
      'eight_to_twenty_characters': '8到20个字符',
      'letters_numbers_special_characters': '字母、数字和特殊字符',
      'password_requirements_detail': '密码要求：8-20位，包含字母和数字',
      'username_label': '用户名',
      'terms_of_service': '服务条款',
      'privacy_policy': '隐私政策',
      'agree_to_terms_prefix': '继续即表示您同意HeatLink的 ',
      'agree_to_terms_middle': ' 并确认您已阅读HeatLink的 ',
      'agree_to_terms_suffix': ' 以了解我们如何收集、使用和共享您的数据。',
      'please_enter_code_sent_to_email': '请输入发送到您的邮箱 ',
      'for_verification': ' 的4位验证码。',
      'request_new_code_in': '在 ',
      'seconds': ' 秒后请求新验证码',
      'send_again': '重新发送',
      'verification_failed': '验证失败',
      'send_failed': '发送失败',
      'request_error': '请求错误',
      'verify_button': '验证',

      // Feedback Page
      'feedback_title': '反馈',
      'feedback_hint': '请输入您的反馈',
      'submit': '提交',
      'feedback_submitted': '反馈提交成功',
      'feedback_failed': '反馈提交失败',
      'failed_to_send_feedback': '发送反馈失败',

      // Feedback Page
      'question_about': '问题类型',
      'tell_more_info': '告诉我更多信息',
      'input_content': '输入内容',
      'select_question_type': '请至少选择一个问题类型',
      'enter_feedback_content': '请输入反馈内容',
      'upload_logs_help': '上传日志可以帮助我们更快地识别和修复问题。',
      'send': '发送',
      'retry': '重试',
      'device_trouble_msg': '无法找到您的设备？请确认设备是否已开机，或手动添加。点击',
      'device_trouble_suffix': '进行故障排查',

      // Device Connect Page
      'auto_detecting': '自动检测中',
      'turn_on_bluetooth': '请打开蓝牙',
      'scanning': '扫描中...',
      'scan_devices': '扫描设备',
      'manually_adding': '添加设备',
      'unknown_device': '未知设备',

      // Unit Switching Page
      'unit_switching_title': '单位切换',
      'temperature_unit': '温度单位',
      'celsius': '摄氏度 (°C)',
      'fahrenheit': '华氏度 (°F)',

      // Meal Time Page
      'meal_time_title': '用餐时间',
      'select_time': '选择时间',
      'hour': '小时',
      'minute': '分钟',
      'select_duration': '选择时长',
      'select_end_time': '选择结束时间',
      'warming_duration': '保温时长',
      'hours': '小时',
      'setting_heat_duration': '设置加热时长',
      'setting_temperature': '设置温度',
      'setting_end_time': '设置结束时间',
      'remind': '提醒',
      'device_not_connected': '设备未连接。请先连接您的设备。',
      'keep_warm_started': '保温已成功启动',
      'keep_warm_stopped': '保温已成功停止',
      'heat_started': '加热已成功启动',
      'heat_stopped': '加热已成功停止',
      'heat_started_but_reminder_failed': '加热已启动，但提醒设置失败',
      'timing_heating_started': '定时加热已成功启动',
      'timing_heating_stopped': '定时加热已成功停止',
      'command_failed': '发送命令失败，请重试。',
      'please_select_temperature': '请选择温度',
      'heating_time_range': '加热时间必须在20-50分钟之间',
      'heating_time_exceed': '加热时间不能超过5小时',
      'end_time_exceed': '结束时间不能超过当前时间5小时',
      'end_time_past': '结束时间不能早于当前时间',
      'heating_duration_too_long': '加热时长过长，无法在设定时间前完成',

      // Calendar
      'calendar_permission_denied': '日历权限被拒绝',
      'calendar_permission_denied_detail': '日历权限被拒绝。请在设置中启用以使用提醒功能。',
      'failed_to_access_calendar': '访问日历失败',
      'failed_to_retrieve_calendars': '获取日历列表失败',
      'no_calendars_available': '没有可用的日历',
      'event_saved_to_calendar': '事件已保存到日历',
      'saved_to_calendar': '已保存到日历',
      'calendar_reminder_created_successfully': '日历提醒创建成功',
      'failed_to_save_to_calendar': '保存到日历失败',
      'error': '错误',

      // Unit Switching
      'unit_switching_description': '您可以在这里设置温度的显示单位',
      'fahrenheit': '华氏度',
      'centigrade': '摄氏度',
      'temperature_unit_changed_to': '温度单位已更改为',
      'failed_to_send_command_try_again': '发送命令失败，请重试',
      'unknown_error': '未知错误',
    },
  };

  String t(String key) =>
      _localizedValues[locale.languageCode]?[key] ??
      _localizedValues['en']![key] ??
      key;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
