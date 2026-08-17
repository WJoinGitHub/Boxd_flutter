import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/pages/device/device_connect_page.dart';
import 'package:flutter_boxd_app_flow/pages/setting/setting_page.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/pages/login/email_login_page.dart';
import 'package:flutter_boxd_app_flow/services/ble_service.dart';
import 'package:flutter_boxd_app_flow/services/ble_protocol.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_boxd_app_flow/pages/heat_page.dart';
import 'package:flutter_boxd_app_flow/pages/heating_time_page.dart';
import 'package:flutter_boxd_app_flow/pages/keep_warm_page.dart';
import 'package:flutter_boxd_app_flow/utils/app_storage.dart';
import 'package:flutter_boxd_app_flow/widgets/home_page_header.dart';
import 'package:flutter_boxd_app_flow/widgets/home_notification_popup.dart';
import 'package:flutter_boxd_app_flow/widgets/home_welcome_connect_popup.dart';
import 'package:flutter_boxd_app_flow/models/device_model.dart';
import 'package:flutter_boxd_app_flow/models/app_notification.dart';
import 'package:flutter_boxd_app_flow/utils/app_toast.dart';
import 'package:flutter_boxd_app_flow/utils/dialog_button_styles.dart';
import 'package:flutter_boxd_app_flow/utils/ble_device_name_match.dart';
import 'package:flutter_boxd_app_flow/utils/ble_product_line_assets.dart';
import 'package:flutter_boxd_app_flow/app_route_observer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with WidgetsBindingObserver, RouteAware {
  bool connected = false;
  int temperature = 0;
  int batteryLevel = 0;
  Map<String, dynamic>? deviceDetail;
  String temperatureUnit = '°C';
  List<DeviceModel> _devices = [];
  DeviceModel? _currentDevice;
  bool _wasLoggedIn = false;
  bool _isInitialized = false;
  DeviceState? _deviceState;
  int? _mealTime; // 设备工作结束时间（从00:00开始的总分钟数）
  int? _remainingHeatingTime; // 剩余加热时间（分钟）
  Timer? _connectionCheckTimer;
  bool _isPoweredOff = false; // 设备是否已关机
  bool _isConnecting = false; // 是否正在连接设备
  int? _connectCountdown; // 连接倒计时（秒）
  Timer? _connectTimer; // 连接倒计时定时器
  /// 连接总超时定时器（实例级，便于切换设备时取消上一轮）
  Timer? _connectTimeoutTimer;
  /// 连接会话号：每次发起/取消连接递增，过期会话不得再断线或改 UI
  int _connectSessionId = 0;
  Future<void>? _loadDevicesFuture; // 防止设备列表并发重复请求
  /// 服务端未读通知数（仅正式登录用户）；用于首页消息角标
  int _unreadNotificationCount = 0;

  /// 本次进入首页仅请求一次运营弹窗（已登录非游客）
  bool _homeNotificationPopupRequested = false;

  final bleService = BleService();

  @override
  void initState() {
    super.initState();
    print("HomePage initState start");
    WidgetsBinding.instance.addObserver(this);
    _wasLoggedIn = UserService().isLoggedIn;
    _loadTemperatureUnit();
    _init().then((_) {
      _isInitialized = true;
      print('[HOME] 初始化完成');
      // 未读角标；运营弹窗已在 _autoLogin 中尽早请求，避免重复弹两次
      _refreshUnreadNotificationCountOnHomeVisible();
    });

    // 注册401错误回调，用于清空设备列表
    UserService().onUnauthorized = () {
      if (mounted) {
        // 与登出一致：清空列表并断开蓝牙，避免下一账号误用连接
        bleService.disconnect();
        setState(() {
          _devices = [];
          _currentDevice = null;
          _wasLoggedIn = false;
          connected = false;
          temperature = 0;
          batteryLevel = 0;
          _deviceState = null;
          _mealTime = null;
          _remainingHeatingTime = null;
          deviceDetail = null;
          _unreadNotificationCount = 0;
        });
        print('[HOME] 401/未授权，已清空设备列表并断开蓝牙');
      }
    };

    bleService.statusStream.listen((status) {
      if (mounted) {
        setState(() {
          // 更新设备状态
          _deviceState = status.state;

          // 根据设备状态更新开关机状态
          if (status.state == DeviceState.disabled) {
            // 设备关机状态
            _isPoweredOff = true;
            print('[HOME] 设备已关机');
          } else if (status.state != DeviceState.ready) {
            // 设备不是待机状态，说明已开机
            _isPoweredOff = false;
          }

          // 更新结束时间（mealTime）- 用于定时模式
          if (status.mealTime != null) {
            _mealTime = status.mealTime;
            print('[HOME] 更新结束时间: $_mealTime 分钟（从00:00开始）');
          }

          // 更新剩余加热时间（用于保温和加热模式）
          if (status.remainingHeatingTime != null) {
            _remainingHeatingTime = status.remainingHeatingTime;
            print('[HOME] 剩余加热时间: ${status.remainingHeatingTime}分钟');
          }

          // 更新电量
          if (status.batteryLevel != null) {
            print('[HOME] 原始电量值: ${status.batteryLevel}');
            final level = status.batteryLevel!;
            if (level >= 1 && level <= 4) {
              batteryLevel = level * 25;
            } else {
              batteryLevel = level;
            }
            print('[HOME] 转换后电量: $batteryLevel%');
          }
          // 更新温度
          if (status.temperature != null) {
            temperature = status.temperature!;
            print('[HOME] 更新温度: $temperature°C');
          }
          // 更新温度单位（优先使用设备返回的单位）
          if (status.isFahrenheit != null) {
            temperatureUnit = status.isFahrenheit! ? '°F' : '°C';
            print('[HOME] 更新温度单位: $temperatureUnit（来自设备）');
          }
          // 如果设备状态变为待机或关机，清除剩余加热时间
          if (status.state == DeviceState.ready ||
              status.state == DeviceState.disabled) {
            _remainingHeatingTime = null;
            _mealTime = null;
          }
        });
      }
    });

    // 定期检查连接状态，如果断开则清除数据
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final isConnected = bleService.isConnected;
      if (connected != isConnected) {
        setState(() {
          connected = isConnected;
          if (!isConnected) {
            // 断开连接时清除所有数据
            print('[HOME] 设备已断开，清除数据');
            temperature = 0;
            batteryLevel = 0;
            _deviceState = null;
            _mealTime = null;
            _remainingHeatingTime = null;
            deviceDetail = null;
          }
        });
      }
    });
  }

  /// 根据电池电量获取对应的图标
  AssetGenImage _getBatteryIcon(int level) {
    if (level >= 100) {
      return Assets.home.images.devBattery;
    } else if (level >= 75) {
      return Assets.home.images.devBattery75;
    } else if (level >= 50) {
      return Assets.home.images.devBattery50;
    } else {
      // 0-49% 都使用 devBattery25
      return Assets.home.images.devBattery25;
    }
  }

  /// 将分钟数转换为时分格式（HH:MM）
  String _formatMinutesToTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTemperatureUnit() async {
    final unit = await AppStorage.loadUnit();
    if (mounted) {
      setState(() => temperatureUnit = unit);
    }
  }

  bool _isHomeRouteCurrent() {
    if (!mounted) return false;
    return ModalRoute.of(context)?.isCurrent ?? false;
  }

  /// 首页可见时刷新未读角标与运营弹窗（子页返回、从后台回到前台；Android/iOS 共用）
  void _refreshHomeMessagesOnVisible({bool requireRouteCurrent = true}) {
    if (!mounted || !_isInitialized) return;
    if (requireRouteCurrent && !_isHomeRouteCurrent()) return;
    if (!UserService().isLoggedIn || UserService().isGuestMode) {
      if (_unreadNotificationCount != 0) {
        setState(() => _unreadNotificationCount = 0);
      }
      return;
    }
    unawaited(_fetchUnreadNotificationCount());
    unawaited(_fetchAndShowHomeNotificationPopup());
  }

  void _refreshUnreadNotificationCountOnHomeVisible() {
    if (!mounted) return;
    if (!UserService().isLoggedIn || UserService().isGuestMode) {
      if (_unreadNotificationCount != 0) {
        setState(() => _unreadNotificationCount = 0);
      }
      return;
    }
    unawaited(_fetchUnreadNotificationCount());
  }

  Future<void> _fetchUnreadNotificationCount() async {
    if (!UserService().isLoggedIn || UserService().isGuestMode) {
      if (mounted) setState(() => _unreadNotificationCount = 0);
      return;
    }
    try {
      final result = await ApiClient.getNotificationsUnreadCount();
      if (!mounted) return;
      final n = _parseUnreadCount(result);
      setState(() => _unreadNotificationCount = n);
    } catch (_) {
      if (mounted) setState(() => _unreadNotificationCount = 0);
    }
  }

  int _parseUnreadCount(Map<String, dynamic> result) {
    if (result['code'] != 200) return 0;
    final data = result['data'];
    if (data is! Map) return 0;
    final raw = data['unread_count'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  /// 首次进入首页（已登录非游客）拉取弹窗数据；有内容则展示（无标题）
  void _requestHomeNotificationPopupOnce() {
    if (_homeNotificationPopupRequested) return;
    if (!UserService().isLoggedIn || UserService().isGuestMode) return;
    _homeNotificationPopupRequested = true;
    unawaited(_fetchAndShowHomeNotificationPopup());
  }

  Future<void> _fetchAndShowHomeNotificationPopup() async {
    if (!UserService().isLoggedIn || UserService().isGuestMode) return;
    try {
      final result = await ApiClient.getNotificationPopup();
      if (!mounted) return;
      final data = AppNotification.fromPopupApiResponse(result);
      if (data == null) return;
      await HomeNotificationPopup.show(
        context,
        data,
        markReadWhenShown: true,
        onMarkedRead: () {
          if (mounted) unawaited(_fetchUnreadNotificationCount());
        },
      );
    } catch (_) {
      // 静默失败
    }
  }

  /// 首页有绑定设备时请求欢迎弹窗（不依赖蓝牙是否已连接）
  void _requestWelcomePopupIfNeeded() {
    if (!mounted) return;
    if (_devices.isEmpty) return;
    if (!UserService().isLoggedIn || UserService().isGuestMode) return;
    unawaited(HomeWelcomeConnectPopup.fetchAndShowIfNeeded(context));
  }

  @override
  void didPush() => _refreshHomeMessagesOnVisible();

  @override
  void didPopNext() => _refreshHomeMessagesOnVisible();

  Future<void> _init() async {
    await _autoLogin();
    // 登录后检查状态是否变化
    final isLoggedIn = UserService().isLoggedIn;
    if (!_wasLoggedIn && isLoggedIn) {
      print('[HOME] _init 检测到登录状态变化，更新 _wasLoggedIn');
      _wasLoggedIn = isLoggedIn;
    }

    // 如果未登录且不是游客模式，跳转到登录页面
    // 游客模式可以使用app，不需要跳转
    if (!isLoggedIn && !UserService().isGuestMode && mounted) {
      print('[HOME] 未登录且不是游客模式，跳转到登录页面');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EmailLoginPage()),
      );
      // 即使跳转到登录页面，也标记为已初始化，避免后续重复调用
      _isInitialized = true;
      return;
    }

    // 加载设备列表并自动连接
    await _autoConnect();
  }

  Future<void> _autoLogin() async {
    print('[HOME] 开始自动登录...');
    final hasToken = await UserService().loadFromLocal();
    print('[HOME] loadFromLocal 结果: $hasToken');

    // 运营弹窗：token 就绪后即请求，不等待 profile / 设备列表 / 蓝牙（与 _init().then 解耦）
    if (mounted &&
        hasToken &&
        UserService().isLoggedIn &&
        !UserService().isGuestMode) {
      _requestHomeNotificationPopupOnce();
    }

    if (hasToken) {
      // 自动登录成功后调用 user/profile 接口刷新用户信息
      try {
        await UserService().fetchUserInfo();
        print(
            '[HOME] 用户信息已刷新: ${UserService().currentUser?.email}, 昵称: ${UserService().currentUser?.nickname}');
      } catch (e) {
        print('[HOME] 获取用户信息失败: $e');
        // 如果获取用户信息失败（可能是401），确保UI更新
      }
      print('[HOME] isLoggedIn: ${UserService().isLoggedIn}');
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadDevices() async {
    // 如果已有进行中的请求，直接复用并等待，避免并发重复请求
    if (_loadDevicesFuture != null) {
      await _loadDevicesFuture;
      return;
    }

    final completer = Completer<void>();
    _loadDevicesFuture = completer.future;
    try {
      final result = await ApiClient.getDevices(page: 1, pageSize: 100);
      if (result['code'] == 200 && result['data'] != null) {
        final raw = result['data'] as List;
        final List<DeviceModel> devices = [];
        final userId = UserService().currentUser?.id;

        for (final item in raw) {
          if (item is! Map) continue;
          final m = Map<String, dynamic>.from(item);
          final du = m['device_uuid']?.toString();
          String? localName;
          if (userId != null &&
              userId.isNotEmpty &&
              du != null &&
              du.isNotEmpty) {
            localName = await AppStorage.loadDeviceLocalName(userId, du);
            if (localName != null && localName.isEmpty) {
              localName = null;
            }
          }
          devices.add(DeviceModel.fromJson(m, localName: localName));
        }

        if (mounted) {
          // 若当前确实连着某台设备，优先把首页当前设备指向这台，避免“显示A，实际连B”
          String? connectedUuid;
          if (bleService.isConnected) {
            try {
              connectedUuid = await bleService.getDeviceUuid();
            } catch (_) {
              connectedUuid = null;
            }
          }

          setState(() {
            _devices = devices;
            // 列表为空时清空当前设备，以便显示空设备列表 UI
            if (devices.isEmpty) {
              _currentDevice = null;
            } else {
              DeviceModel? connectedDevice;
              if (connectedUuid != null && connectedUuid.isNotEmpty) {
                final targetUuid = connectedUuid.toUpperCase();
                for (final d in devices) {
                  if (d.deviceUuid.toUpperCase() == targetUuid) {
                    connectedDevice = d;
                    break;
                  }
                }
              }
              if (connectedDevice != null) {
                _currentDevice = connectedDevice;
              } else {
                // 当前设备不在新列表中时清空（例如已被移除）
                if (_currentDevice != null &&
                    !devices.any(
                        (d) => d.deviceUuid == _currentDevice!.deviceUuid)) {
                  _currentDevice = null;
                }
                if (_currentDevice == null && devices.isNotEmpty) {
                  _currentDevice = devices.first;
                }
              }
            }
          });
          // 有绑定设备时请求欢迎弹窗（是否展示由接口 should_show 决定）
          if (devices.isNotEmpty && mounted) {
            _requestWelcomePopupIfNeeded();
          }
          // 云端已无绑定设备时，必须断开 BLE，否则 UI 仍像「已连接」
          if (devices.isEmpty && bleService.isConnected) {
            await bleService.disconnect();
            if (mounted) {
              setState(() {
                connected = false;
                temperature = 0;
                batteryLevel = 0;
                _deviceState = null;
                _mealTime = null;
                _remainingHeatingTime = null;
                deviceDetail = null;
              });
            }
          }
        }
      }
    } catch (e) {
      print('[HOME] 加载设备列表失败: $e');
    } finally {
      completer.complete();
      _loadDevicesFuture = null;
    }
  }

  Future<void> _autoConnect({bool skipLoadDevices = false}) async {
    print('[HOME] 尝试自动连接...');
    // 只有在已登录或游客模式下才加载设备列表
    if (!UserService().isLoggedIn && !UserService().isGuestMode) {
      print('[HOME] 未登录且不是游客模式，跳过加载设备列表');
      return;
    }

    if (!skipLoadDevices) {
      await _loadDevices();
    }

    // 游客仅同步云端绑定列表，不自动连蓝牙（避免登出后同一台物理设备仍被连上）
    if (UserService().isGuestMode) {
      print('[HOME] 游客模式，不自动连接蓝牙');
      return;
    }

    if (_devices.isEmpty) {
      print('[HOME] 没有绑定的设备');
      return;
    }

    // 自动连接：优先选「deviceName」与当前已连接 BLE 的 platformName 一致的那台绑定设备
    DeviceModel target = _devices.first;
    var pickedByConnectedBleName = false;
    try {
      final connectedDevices = await FlutterBluePlus.connectedSystemDevices;
      for (final bound in _devices) {
        final exactHit = connectedDevices.any(
          (c) =>
              bleNameMatchLevel(bound.deviceName, c.platformName) ==
              BleNameMatchLevel.exact,
        );
        if (exactHit) {
          target = bound;
          pickedByConnectedBleName = true;
          print(
              '[HOME] 自动连接：已连接 BLE 名称精确匹配，选中 ${bound.deviceUuid} (${bound.deviceName})');
          break;
        }
      }
      if (!pickedByConnectedBleName) {
        for (final bound in _devices) {
          final prefixHit = connectedDevices.any(
            (c) =>
                bleNameMatchLevel(bound.deviceName, c.platformName) ==
                BleNameMatchLevel.prefix,
          );
          if (prefixHit) {
            target = bound;
            pickedByConnectedBleName = true;
            print(
                '[HOME] 自动连接：已连接 BLE QIMI 前缀匹配，选中 ${bound.deviceUuid} (${bound.deviceName})');
            break;
          }
        }
      }
      if (!pickedByConnectedBleName && _devices.length > 1) {
        print(
            '[HOME] 自动连接：无已连接 BLE 与列表 deviceName 匹配，使用列表首台 ${target.deviceUuid}');
      }
    } catch (e) {
      print('[HOME] 自动连接选设备异常: $e');
    }
    if (mounted && _currentDevice?.deviceUuid != target.deviceUuid) {
      setState(() {
        _currentDevice = target;
      });
    }
    await _connectToDevice(target, isAutoConnect: true);
  }

  /// 获取首页展示的设备名（多设备时也不再追加编号）
  String _getDisplayDeviceName() {
    if (_currentDevice == null) return 'HeatLink';
    return _currentDevice!.headerDisplayName();
  }

  /// 首页设备大图：已连接用 BLE 广播名，未连接用绑定 `device_name`
  String? _bleNameForHeroImage() {
    if (connected) {
      final platformName = bleService.connectedPlatformName?.trim();
      if (platformName != null && platformName.isNotEmpty) {
        return platformName;
      }
    }
    final name = _currentDevice?.deviceName.trim();
    if (name != null && name.isNotEmpty) return name;
    return null;
  }

  Future<void> _showEditDeviceNameDialog() async {
    if (_currentDevice == null) return;

    final currentName = _getDisplayDeviceName();
    final controller = TextEditingController(text: currentName);

    final l10n = AppLocalizations.of(context);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.t('edit_device_name')),
        content: TextField(
          controller: controller,
          cursorColor: AppColors.orange,
          decoration: InputDecoration(
            hintText: l10n.t('enter_device_name'),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.orange, width: 2),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.orange, width: 1),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            style: DialogButtonStyles.cancel,
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.t('cancel')),
          ),
          TextButton(
            style: DialogButtonStyles.primaryAction,
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.t('save')),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      final userId = UserService().currentUser?.id;
      final deviceUuid = _currentDevice!.deviceUuid;

      if (userId != null && userId.isNotEmpty && deviceUuid.isNotEmpty) {
        await AppStorage.saveDeviceLocalName(userId, deviceUuid, newName);
        setState(() {
          _currentDevice = _currentDevice!.copyWith(localName: newName);
          // 与切换设备弹窗、Header 共用 _devices，必须同步本地名
          _devices = [
            for (final d in _devices)
              if (d.deviceUuid == deviceUuid)
                d.copyWith(localName: newName)
              else
                d,
          ];
        });

        if (mounted) {
          AppToast.show(context, l10n.t('device_name_saved'));
        }
      }
    }
  }

  Future<void> _showDeviceSelector() async {
    if (_devices.isEmpty) return;

    final selectedDevice = await showModalBottomSheet<DeviceModel>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                AppLocalizations.of(context).t('select_device'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: _devices.length,
              itemBuilder: (context, index) {
                final device = _devices[index];
                final deviceUuid = device.deviceUuid;
                final title = device.listDisplayName();
                final isCurrent = _currentDevice?.deviceUuid == deviceUuid;
                final isDeviceConnected = connected && isCurrent;

                return ListTile(
                  title: Text(
                    title,
                    style: TextStyle(
                      color: isCurrent ? AppColors.orange : null,
                      fontWeight: isCurrent ? FontWeight.w600 : null,
                    ),
                  ),
                  trailing: isCurrent
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isDeviceConnected)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  AppLocalizations.of(context).t('connected'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                            const Icon(Icons.check, color: Colors.green),
                          ],
                        )
                      : null,
                  selected: isCurrent,
                  onTap: () {
                    Navigator.pop(context, device);
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (selectedDevice != null &&
        selectedDevice.deviceUuid != _currentDevice?.deviceUuid) {
      await _switchDevice(selectedDevice);
    }
  }

  Future<void> _switchDevice(DeviceModel newDevice) async {
    // 作废进行中的连接（含 15s 超时），避免切换后旧超时把新连接断开
    _invalidateConnectSession(reason: '切换设备');

    // 断开当前设备
    if (connected && bleService.isConnected) {
      await bleService.disconnect();
      if (mounted) {
        setState(() => connected = false);
      }
    }

    // 设置新设备为当前设备
    if (mounted) {
      setState(() {
        _currentDevice = newDevice;
      });
    }

    // 连接新设备
    await _connectToDevice(newDevice);
  }

  /// 作废当前连接会话：取消超时/倒计时与扫描，后续旧流程全部短路。
  void _invalidateConnectSession({String reason = ''}) {
    _connectSessionId++;
    _connectTimeoutTimer?.cancel();
    _connectTimeoutTimer = null;
    _connectTimer?.cancel();
    _connectTimer = null;
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      print('[HOME] 停止扫描失败($reason): $e');
    }
    if (reason.isNotEmpty) {
      print('[HOME] 作废连接会话($_connectSessionId): $reason');
    }
  }

  Future<void> _connectToDevice(DeviceModel device,
      {bool isAutoConnect = false}) async {
    // 新会话：取消上一轮 15s 超时，防止切换设备时并发连接互相踩踏
    _invalidateConnectSession(reason: isAutoConnect ? '自动连接' : '开始连接');
    final sessionId = _connectSessionId;

    if (mounted) {
      setState(() {
        _isConnecting = true;
        _connectCountdown = 15; // 开始15秒倒计时
      });
    }

    // 启动倒计时定时器
    _connectTimer?.cancel();
    _connectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (sessionId != _connectSessionId) {
        timer.cancel();
        return;
      }
      if (mounted) {
        setState(() {
          if (_connectCountdown != null && _connectCountdown! > 0) {
            _connectCountdown = _connectCountdown! - 1;
          } else {
            timer.cancel();
            _connectCountdown = null;
          }
        });
      } else {
        timer.cancel();
      }
    });

    // 设置15秒总超时
    bool timeoutOccurred = false;

    try {
      final deviceUuid = device.deviceUuid;
      print('[HOME] 连接设备: $deviceUuid (session=$sessionId)');

      // 启动超时定时器
      _connectTimeoutTimer?.cancel();
      _connectTimeoutTimer = Timer(const Duration(seconds: 15), () {
        if (sessionId != _connectSessionId) {
          print('[HOME] 忽略过期连接超时 (session=$sessionId)');
          return;
        }
        timeoutOccurred = true;
        // 清除倒计时
        _connectTimer?.cancel();
        if (mounted) {
          setState(() {
            _connectCountdown = null;
          });
        }
        print('[HOME] 连接超时（15秒），停止连接');
        // 停止扫描
        try {
          FlutterBluePlus.stopScan();
        } catch (e) {
          print('[HOME] 停止扫描失败: $e');
        }
        // 断开连接
        try {
          bleService.disconnect();
        } catch (e) {
          print('[HOME] 断开连接失败: $e');
        }
      });

      bool isStale() => sessionId != _connectSessionId;

      final connectedDevices = await FlutterBluePlus.connectedSystemDevices;
      if (timeoutOccurred || !mounted || isStale()) {
        _connectTimeoutTimer?.cancel();
        return;
      }

      BluetoothDevice? targetDevice;

      // 仅精确匹配：Android 上断开后旧机可能仍短暂出现在 connectedSystemDevices；
      // 若两台设备 QIMI 前两段相同，前缀匹配会误连旧机而 UI 已是新选中的绑定设备。
      for (var d in connectedDevices) {
        if (timeoutOccurred || isStale()) break;
        if (bleNameMatchLevel(device.deviceName, d.platformName) ==
            BleNameMatchLevel.exact) {
          print('[HOME] 找到已连接的设备（名称精确匹配）: ${d.platformName}');
          targetDevice = d;
          break;
        }
      }

      if (targetDevice == null && !timeoutOccurred && !isStale()) {
        // 检查蓝牙状态（启动时可能为 unknown：暂停 1.5 秒后重试，最多检测 3 次）
        BluetoothAdapterState bluetoothAdapterState =
            await FlutterBluePlus.adapterState.first;
        for (int attempt = 1;
            attempt < 3 &&
                bluetoothAdapterState == BluetoothAdapterState.unknown;
            attempt++) {
          await Future.delayed(const Duration(milliseconds: 1500));
          if (!mounted || timeoutOccurred || isStale()) return;
          bluetoothAdapterState = await FlutterBluePlus.adapterState.first;
        }
        if (bluetoothAdapterState == BluetoothAdapterState.unknown) {
          bluetoothAdapterState = BluetoothAdapterState.on;
        }
        if (bluetoothAdapterState != BluetoothAdapterState.on) {
          print('[HOME] 蓝牙未开启，无法扫描');
          _connectTimeoutTimer?.cancel();
          if (mounted && !isAutoConnect && !isStale()) {
            AppToast.show(
              context,
              AppLocalizations.of(context).t('turn_on_bluetooth'),
            );
          }
          return;
        }

        print('[HOME] 开始扫描设备...');
        print('[HOME] 目标 deviceName=${device.deviceName}（按名称匹配 BLE）');

        final deviceCompleter = Completer<BluetoothDevice?>();
        StreamSubscription? scanSubscription;
        bool scanStarted = false;
        // 仅前缀匹配时不在首轮回调里立刻连接，等扫描结束再用，避免多台 QIMI 误连
        BluetoothDevice? scanPrefixFallback;

        try {
          // 先设置监听器，再启动扫描，避免丢失结果
          scanSubscription = FlutterBluePlus.scanResults.listen((results) {
            if (timeoutOccurred ||
                isStale() ||
                deviceCompleter.isCompleted) {
              return;
            }

            print('[HOME] 收到扫描结果: ${results.length} 个设备');
            BluetoothDevice? batchExact;
            for (var r in results) {
              if (timeoutOccurred ||
                  isStale() ||
                  deviceCompleter.isCompleted) {
                break;
              }

              print(
                  '[HOME] 扫描到设备: ${r.device.platformName}, remoteId=${r.device.remoteId.str}');

              final level =
                  bleNameMatchLevel(device.deviceName, r.device.platformName);
              if (level == BleNameMatchLevel.exact) {
                batchExact = r.device;
                break;
              }
              if (level == BleNameMatchLevel.prefix) {
                scanPrefixFallback ??= r.device;
              }
            }
            if (batchExact != null && !deviceCompleter.isCompleted) {
              print('[HOME] 找到匹配的设备（名称精确）: ${batchExact.platformName}');
              deviceCompleter.complete(batchExact);
            }
          });

          // 启动扫描，超时时间15秒
          try {
            await FlutterBluePlus.startScan(
                timeout: const Duration(seconds: 15));
            scanStarted = true;
            print('[HOME] 扫描已启动，将扫描15秒');
          } catch (e) {
            print('[HOME] 启动扫描失败: $e');
            scanSubscription?.cancel();
            if (!deviceCompleter.isCompleted) {
              deviceCompleter.complete(null);
            }
            return;
          }

          if (isStale()) {
            scanSubscription?.cancel();
            if (scanStarted) {
              try {
                await FlutterBluePlus.stopScan();
              } catch (_) {}
            }
            return;
          }

          // 等待扫描完成或超时，等待时间15秒
          try {
            targetDevice = await deviceCompleter.future.timeout(
              const Duration(seconds: 15),
              onTimeout: () => null,
            );
            if (isStale()) return;
            final prefixCandidate = scanPrefixFallback;
            if (targetDevice == null && prefixCandidate != null) {
              print(
                  '[HOME] 扫描未等到精确名称匹配，使用 QIMI 前缀候选: ${prefixCandidate.platformName}');
              targetDevice = prefixCandidate;
            } else if (targetDevice == null) {
              print('[HOME] 扫描超时（15秒），未找到名称匹配的设备');
            }
          } catch (e) {
            print('[HOME] 扫描等待失败: $e');
          }

          // 停止扫描（无论是否找到设备）
          scanSubscription?.cancel();
          if (scanStarted) {
            try {
              await FlutterBluePlus.stopScan();
              print('[HOME] 扫描已停止');
            } catch (e) {
              print('[HOME] 停止扫描失败: $e');
            }
          }
        } catch (e) {
          print('[HOME] 扫描过程出错: $e');
          scanSubscription?.cancel();
          if (!deviceCompleter.isCompleted) {
            deviceCompleter.complete(null);
          }
          // 确保停止扫描
          if (scanStarted) {
            try {
              await FlutterBluePlus.stopScan();
              print('[HOME] 异常处理：扫描已停止');
            } catch (e) {
              print('[HOME] 停止扫描失败: $e');
            }
          }
        }
      }

      if (isStale()) {
        print('[HOME] 连接会话已过期，中止 (session=$sessionId)');
        return;
      }

      if (timeoutOccurred) {
        _connectTimeoutTimer?.cancel();
        // 自动连接失败时不显示提示
        if (mounted && !isAutoConnect) {
          AppToast.show(
            context,
            AppLocalizations.of(context).t('failed_to_connect'),
          );
        }
        return;
      }

      if (targetDevice != null && mounted) {
        // 在连接前再次检查超时
        if (timeoutOccurred || isStale()) {
          _connectTimeoutTimer?.cancel();
          return;
        }

        final success =
            await bleService.connect(targetDevice, skipBind: true).timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            print('[HOME] BLE服务连接超时');
            timeoutOccurred = true;
            return false;
          },
        );

        if (isStale()) {
          // 已被新一轮连接取代：若本次误连上，断开以免占用
          print('[HOME] 过期会话的连接结果，断开并忽略 (session=$sessionId)');
          if (success) {
            try {
              await bleService.disconnect();
            } catch (_) {}
          }
          return;
        }

        _connectTimeoutTimer?.cancel();

        if (success && mounted && !timeoutOccurred) {
          // 清除倒计时
          _connectTimer?.cancel();
          setState(() {
            // 以本次连接目标为准，避免“已连接状态”和“当前设备”错位
            _currentDevice = device;
            connected = true;
            _isConnecting = false;
            _connectCountdown = null;
          });
          print('[HOME] 设备连接成功');
          // 获取设备详情
          try {
            final detail = await ApiClient.getDeviceDetail(deviceUuid);
            if (detail['code'] == 200 &&
                detail['data'] != null &&
                mounted &&
                !isStale()) {
              setState(() => deviceDetail = detail['data']);
            }
          } catch (e) {
            print('[HOME] 获取设备详情失败: $e');
          }
          // 自动连接时不显示成功提示
          if (!isAutoConnect && mounted && !isStale()) {
            AppToast.show(
              context,
              AppLocalizations.of(context).t('connection_success'),
            );
          }
        } else if (mounted && timeoutOccurred && !isStale()) {
          // 清除倒计时
          _connectTimer?.cancel();
          setState(() {
            _isConnecting = false;
            _connectCountdown = null;
          });
          // 自动连接失败时不显示提示
          if (!isAutoConnect) {
            AppToast.show(
              context,
              AppLocalizations.of(context).t('failed_to_connect'),
            );
          }
        }
      } else if (mounted && !timeoutOccurred && !isStale()) {
        // 未找到设备，确保停止扫描
        _connectTimeoutTimer?.cancel();
        try {
          await FlutterBluePlus.stopScan();
          print('[HOME] 未找到设备，扫描已停止');
        } catch (e) {
          print('[HOME] 停止扫描失败: $e');
        }
        // 自动连接失败时不显示提示
        if (!isAutoConnect) {
          AppToast.show(
            context,
            AppLocalizations.of(context).t('device_not_found'),
          );
        }
      }
    } catch (e) {
      if (sessionId == _connectSessionId) {
        _connectTimeoutTimer?.cancel();
      }
      print('[HOME] 连接设备失败: $e');
      // 确保停止扫描
      try {
        await FlutterBluePlus.stopScan();
        print('[HOME] 异常处理：扫描已停止');
      } catch (e) {
        print('[HOME] 停止扫描失败: $e');
      }
      // 自动连接失败时不显示提示
      if (mounted &&
          !timeoutOccurred &&
          !isAutoConnect &&
          sessionId == _connectSessionId) {
        AppToast.show(
          context,
          '${AppLocalizations.of(context).t('failed_to_connect')}: $e',
        );
      }
    } finally {
      if (sessionId == _connectSessionId) {
        _connectTimeoutTimer?.cancel();
        _connectTimeoutTimer = null;
        // 清除倒计时
        _connectTimer?.cancel();
        if (mounted) {
          setState(() {
            _isConnecting = false;
            if (!connected) {
              _connectCountdown = null;
            }
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    _connectTimer?.cancel();
    _connectTimeoutTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    appRouteObserver.unsubscribe(this);
    // BleService 为单例：不在此 dispose，否则会关闭 statusStream，登出再进首页后无法收状态
    // 移除401错误回调
    UserService().onUnauthorized = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
    print('[HOME] didChangeDependencies - _isInitialized: $_isInitialized');
    // 页面恢复时检查登录状态（跳过初始化时的调用）
    if (_isInitialized) {
      // 延迟执行，确保登录状态已更新
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _checkLoginStatusAndRefresh();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('[HOME] didChangeAppLifecycleState: $state');
    if (state == AppLifecycleState.resumed) {
      _checkLoginStatusAndRefresh();
      // 从后台切回前台且当前在首页：拉未读数 + 运营弹窗（Android / iOS）
      _refreshHomeMessagesOnVisible();
    }
  }

  Future<void> _checkLoginStatusAndRefresh() async {
    // 如果还未初始化完成，不执行刷新，避免与_init()重复调用
    if (!_isInitialized) {
      print('[HOME] 还未初始化完成，跳过_checkLoginStatusAndRefresh');
      return;
    }

    final isLoggedIn = UserService().isLoggedIn;
    print(
        '[HOME] _checkLoginStatusAndRefresh - _wasLoggedIn: $_wasLoggedIn, isLoggedIn: $isLoggedIn');

    // 如果从未登录变为已登录，刷新设备列表
    if (!_wasLoggedIn && isLoggedIn) {
      print('[HOME] 检测到登录状态变化，刷新设备列表');
      _wasLoggedIn = isLoggedIn;
      // _autoConnect 内部会先加载设备列表，这里不再重复请求
      await _autoConnect();
      if (mounted) {
        setState(() {});
      }
      _refreshUnreadNotificationCountOnHomeVisible();
    } else if (_wasLoggedIn != isLoggedIn) {
      // 更新状态，但不刷新设备列表（登出等情况）；刷新 UI（如首页消息入口显隐）
      print('[HOME] 登录状态变化（登出）');
      _wasLoggedIn = isLoggedIn;
      if (mounted) {
        setState(() {
          _unreadNotificationCount = 0;
        });
      }
    } else if (isLoggedIn) {
      // 已登录状态下，每次页面显示时刷新设备列表
      print('[HOME] 已登录状态，刷新设备列表');
      await _loadDevices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HomePageHeader(
                            devices: _devices,
                            isConnecting: _isConnecting,
                            connected: connected,
                            currentDevice: _currentDevice,
                            deviceDetail: deviceDetail,
                            unreadNotificationCount: _unreadNotificationCount,
                            onDeviceSelectorTap: _showDeviceSelector,
                            onSettingsReturn: () async {
                              if (mounted) {
                                print('[HOME] 设备列表已变化，刷新列表');
                                await _loadDevices();
                                // 若移除所有设备后列表为空，断开连接并更新状态，以显示空设备列表 UI
                                if (mounted && _devices.isEmpty && connected) {
                                  await bleService.disconnect();
                                  setState(() => connected = false);
                                }
                                // 从「我的设备」解绑等返回后，若仍有绑定设备则尝试自动连接一次（已加载列表，避免重复请求）
                                if (mounted && _devices.isNotEmpty) {
                                  await _autoConnect(skipLoadDevices: true);
                                }
                              }
                            },
                          ),

                          // 设备列表为空时，只显示头像、两行文案、logo图片和addDeviceBig按钮
                          // 游客模式和登录用户都可以看到这个空状态
                          if ((UserService().isLoggedIn ||
                                  UserService().isGuestMode) &&
                              _devices.isEmpty &&
                              !connected) ...[
                            const SizedBox(height: 40),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 100),
                                  SizedBox(
                                    height: 132,
                                    child: Assets.login.images.logo.image(
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 100),
                                  GestureDetector(
                                    onTap: () async {
                                      final result =
                                          await Navigator.of(context).push(
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) =>
                                              const DeviceConnectPage(),
                                        ),
                                      );
                                      if (result == true && mounted) {
                                        await _loadDevices();
                                        setState(() =>
                                            connected = bleService.isConnected);
                                      }
                                    },
                                    child:
                                        Assets.home.images.addDeviceBig.image(
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ]
                          // 有设备或已连接时的正常UI
                          else ...[
                            // 设备名称展示（设备列表不为空时显示）
                            if (_devices.isNotEmpty &&
                                _currentDevice != null) ...[
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  // 连接状态圆点
                                  Container(
                                    width: 15,
                                    height: 15,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: connected
                                          ? AppColors.green
                                          : AppColors.gray5,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 设备名称（紧挨着编辑按钮）
                                  Text(
                                    _getDisplayDeviceName(),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // 编辑按钮（紧挨着设备名称）
                                  GestureDetector(
                                    onTap: _showEditDeviceNameDialog,
                                    child: Assets.home.images.editPencil.image(
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  // 如果设备数量大于1，显示向下箭头
                                  if (_devices.length > 1) ...[
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: _showDeviceSelector,
                                      child: const Icon(
                                        Icons.arrow_drop_down,
                                        color: Colors.black,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                  // 占满剩余空间
                                  const Spacer(),
                                  // 添加设备按钮（在最右边）
                                  GestureDetector(
                                    onTap: () async {
                                      // 游客仅有内存 token，须与 isLoggedIn 同等对待，勿跳转登录页
                                      if (!UserService().isLoggedIn &&
                                          !UserService().isGuestMode) {
                                        await Navigator.of(context).push(
                                          PageRouteBuilder(
                                            fullscreenDialog: true,
                                            pageBuilder: (_, __, ___) =>
                                                const EmailLoginPage(),
                                          ),
                                        );
                                        if (!mounted ||
                                            (!UserService().isLoggedIn &&
                                                !UserService().isGuestMode))
                                          return;
                                      }
                                      final result =
                                          await Navigator.of(context).push(
                                        PageRouteBuilder(
                                          pageBuilder: (_, __, ___) =>
                                              const DeviceConnectPage(),
                                        ),
                                      );
                                      if (result == true && mounted) {
                                        // 绑定设备成功后，刷新设备列表
                                        if (UserService().isLoggedIn ||
                                            UserService().isGuestMode) {
                                          await _loadDevices();
                                        }
                                        setState(() =>
                                            connected = bleService.isConnected);
                                      }
                                    },
                                    child: Assets.home.images.addDevice.image(
                                      width: 21,
                                      height: 21,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // 连接状态显示（仅在未连接且有设备时显示）
                            if (!connected &&
                                _devices.isNotEmpty &&
                                _currentDevice != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // 倒计时显示或连接按钮
                                  if (_connectCountdown != null &&
                                      _connectCountdown! > 0) ...[
                                    // 倒计时显示
                                    Row(
                                      children: [
                                        Text(
                                          l10n
                                              .t('connect_device_countdown')
                                              .replaceAll('{seconds}',
                                                  '$_connectCountdown'),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    AppColors.orange),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else ...[
                                    // 连接按钮（带边框、半圆角）
                                    GestureDetector(
                                      onTap: () async {
                                        if (_currentDevice != null) {
                                          await _connectToDevice(
                                              _currentDevice!);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: AppColors.black,
                                            width: 1,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          l10n.t('connect_device'),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],

                            // 电池显示（设备已连接时，在连接文案下面、设备图片上面）
                            if (connected) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _getBatteryIcon(batteryLevel).image(
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$batteryLevel%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            const SizedBox(height: 20),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 左边：logo图片和温度（设备列表不为空时显示）
                                  if (_devices.isNotEmpty)
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Assets.login.images.logo.image(
                                          width: 145,
                                          fit: BoxFit.contain,
                                        ),
                                        // 温度显示（仅在连接时显示，放在logo下面，间隔40）
                                        if (connected) ...[
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Assets.device.images.temperature
                                                  .image(
                                                width: 31,
                                                fit: BoxFit.contain,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${_getDisplayTemperature()}  ',
                                                style: const TextStyle(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                              GestureDetector(
                                                onTap: _toggleTemperatureUnit,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: const Color(
                                                            0xFF7F8489),
                                                        width: 1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: Text(
                                                    temperatureUnit,
                                                    style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // 剩余时间显示（保温、加热、定时模式）
                                          if (connected &&
                                              (_deviceState ==
                                                      DeviceState.keepWarm ||
                                                  _deviceState ==
                                                      DeviceState.heating ||
                                                  _deviceState ==
                                                      DeviceState.timing)) ...[
                                            Builder(
                                              builder: (context) {
                                                int? remainingMinutes;
                                                // 保温、加热模式：使用剩余加热时间
                                                if (_deviceState ==
                                                        DeviceState.keepWarm ||
                                                    _deviceState ==
                                                        DeviceState.heating) {
                                                  remainingMinutes =
                                                      _remainingHeatingTime;
                                                }
                                                // 定时模式：计算到开饭时间的剩余分钟数
                                                else if (_deviceState ==
                                                        DeviceState.timing &&
                                                    _mealTime != null) {
                                                  final now = DateTime.now();
                                                  // 当前时间从00:00开始的总分钟数
                                                  final currentMinutes =
                                                      now.hour * 60 +
                                                          now.minute;
                                                  // 计算剩余分钟数
                                                  int diff = _mealTime! -
                                                      currentMinutes;
                                                  // 如果为负，说明是明天的时间
                                                  if (diff < 0) {
                                                    diff += 24 * 60; // 加24小时
                                                  }
                                                  remainingMinutes = diff;
                                                }

                                                if (remainingMinutes != null &&
                                                    remainingMinutes > 0) {
                                                  final l10n =
                                                      AppLocalizations.of(
                                                          context);
                                                  return Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      const SizedBox(
                                                          height: 12),
                                                      Text(
                                                        l10n.t('time_left'),
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w400,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      Text(
                                                        _formatMinutesToTime(
                                                            remainingMinutes),
                                                        style: const TextStyle(
                                                          fontSize: 50,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                          ],
                                        ],
                                      ],
                                    )
                                  else
                                    const SizedBox.shrink(),

                                  // 右边设备图片（已连 BLE 名 / 未连 device_name，按产品列表匹配）
                                  homeDeviceHeroImageForBleName(
                                    _bleNameForHeroImage(),
                                    width: 150,
                                    fit: BoxFit.contain,
                                  ),
                                ],
                              ),
                            ),
                            // 三个功能按钮（仅在非空状态时显示）
                            // 游客模式和登录用户都可以看到功能按钮
                            if (!((UserService().isLoggedIn ||
                                    UserService().isGuestMode) &&
                                _devices.isEmpty &&
                                !connected))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 7),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 33),

                                    // 三个功能按钮
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildModeButton(
                                          l10n.t('ins'),
                                          Assets.device.images.devIns
                                              .image(width: 48, height: 47),
                                        ),
                                        _buildModeButton(
                                          l10n.t('heat'),
                                          Assets.device.images.devHeat
                                              .image(width: 44, height: 53),
                                        ),
                                        _buildModeButton(
                                          l10n.t('timer'),
                                          Assets.device.images.devTimer
                                              .image(width: 41, height: 44),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Banner 贴底 / 电源开关 / 停止按钮
            if (connected)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      // 判断是否处于工作状态（保温、加热、定时）
                      final isWorking = _deviceState == DeviceState.keepWarm ||
                          _deviceState == DeviceState.heating ||
                          _deviceState == DeviceState.timing;

                      if (isWorking) {
                        // 显示停止按钮
                        return ElevatedButton(
                          onPressed: () async {
                            final success = await bleService.stopWork();
                            if (mounted) {
                              if (success) {
                                AppToast.show(context, l10n.t('stop'));
                              } else {
                                AppToast.show(
                                  context,
                                  l10n.t('failed_to_power_off'),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            minimumSize: const Size(100, 56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.stop,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.t('stop'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // 显示开机/关机按钮
                        return ElevatedButton(
                          onPressed: () async {
                            if (_isPoweredOff) {
                              // 开机
                              final success = await bleService.startDevice();
                              if (mounted) {
                                if (success) {
                                  setState(() => _isPoweredOff = false);
                                  AppToast.show(
                                      context, l10n.t('device_powered_on'));
                                } else {
                                  AppToast.show(
                                    context,
                                    l10n.t('failed_to_power_on'),
                                  );
                                }
                              }
                            } else {
                              // 关机
                              final success = await bleService.stopDevice();
                              if (mounted) {
                                if (success) {
                                  setState(() => _isPoweredOff = true);
                                  AppToast.show(
                                      context, l10n.t('device_powered_off'));
                                } else {
                                  AppToast.show(
                                    context,
                                    l10n.t('failed_to_power_off'),
                                  );
                                }
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            minimumSize: const Size(100, 56),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPoweredOff
                                    ? Icons.power_settings_new
                                    : Icons.power_settings_new,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isPoweredOff
                                    ? l10n.t('power_on')
                                    : l10n.t('power_off'),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              )
            else
            // 未连接时，如果设备列表为空，不显示banner（空状态已在上面显示）
            // 游客模式和登录用户都遵循这个逻辑
            if (!((UserService().isLoggedIn || UserService().isGuestMode) &&
                _devices.isEmpty))
              Container(
                // 可以在这里添加banner图片，如果将来需要
                height: 0,
              ),
          ],
        ),
      ),
    );
  }

  /// 切换温度单位
  Future<void> _toggleTemperatureUnit() async {
    if (!connected) return;

    final l10n = AppLocalizations.of(context);
    if (_isPoweredOff || _deviceState == DeviceState.disabled) {
      if (mounted) {
        AppToast.show(context, l10n.t('device_is_powered_off'));
      }
      return;
    }

    final newUnit = temperatureUnit == '°C' ? '°F' : '°C';
    await AppStorage.saveUnit(newUnit);
    setState(() => temperatureUnit = newUnit);

    // 发送切换温度单位命令
    await bleService.syncTime();
  }

  /// 获取显示温度（心跳收到的温度已经是转换过的，直接返回）
  int _getDisplayTemperature() {
    return temperature;
  }

  /// 获取结束时间显示文本
  /// 对于定时模式：使用开饭时间（mealTime）
  /// 对于保温和加热模式：根据剩余加热时间计算结束时间
  String? _getEndTimeText() {
    if (_deviceState == null) return null;

    // 定时模式：使用开饭时间
    if (_deviceState == DeviceState.timing && _mealTime != null) {
      // mealTime 是从00:00开始的总分钟数
      final hours = _mealTime! ~/ 60;
      final minutes = _mealTime! % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }

    // 保温和加热模式：根据剩余加热时间计算结束时间
    if ((_deviceState == DeviceState.keepWarm ||
            _deviceState == DeviceState.heating) &&
        _remainingHeatingTime != null &&
        _remainingHeatingTime! > 0) {
      final now = DateTime.now();
      final endTime = now.add(Duration(minutes: _remainingHeatingTime!));
      final hours = endTime.hour;
      final minutes = endTime.minute;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    }

    return null;
  }

  /// 是否应该显示结束时间（在定时、保温、加热状态时显示）
  bool _shouldShowEndTime() {
    if (_deviceState == null) return false;

    // 定时模式：需要开饭时间
    if (_deviceState == DeviceState.timing) {
      return _mealTime != null;
    }

    // 保温和加热模式：需要剩余加热时间
    if (_deviceState == DeviceState.keepWarm ||
        _deviceState == DeviceState.heating) {
      return _remainingHeatingTime != null && _remainingHeatingTime! > 0;
    }

    return false;
  }

  /// 获取模式图片（根据设备状态）
  Widget _getModeImage() {
    // 根据设备状态显示对应图片
    if (_deviceState == null) {
      // 默认显示Ins图片
      return Assets.device.images.devIns.image(
        width: 48,
        height: 47,
        fit: BoxFit.contain,
      );
    }

    switch (_deviceState!) {
      case DeviceState.keepWarm:
        return Assets.device.images.devIns.image(
          width: 48,
          height: 47,
          fit: BoxFit.contain,
        );
      case DeviceState.heating:
        return Assets.device.images.devHeat.image(
          width: 44,
          height: 53,
          fit: BoxFit.contain,
        );
      case DeviceState.timing:
        return Assets.device.images.devTimer.image(
          width: 41,
          height: 44,
          fit: BoxFit.contain,
        );
      case DeviceState.ready:
      default:
        // 待机状态或未知状态，默认显示Ins图片
        return Assets.device.images.devTimer.image(
          width: 41,
          height: 44,
          fit: BoxFit.contain,
        );
    }
  }

  /// 获取模式文案（根据设备状态）
  String _getModeText() {
    // 根据设备状态显示对应文案
    if (_deviceState == null) {
      return 'Keep\nWarm';
    }

    switch (_deviceState!) {
      case DeviceState.keepWarm:
        return 'Keep\nWarm';
      case DeviceState.heating:
        return 'Heat';
      case DeviceState.timing:
        return 'Timer';
      case DeviceState.ready:
      default:
        // 待机状态或未知状态，默认显示Keep Warm
        return 'Keep\nWarm';
    }
  }

  /// 构建功能按钮（带图片 + 文字）
  Widget _buildModeButton(String label, Widget icon) {
    final l10n = AppLocalizations.of(context);
    // 判断当前按钮是否激活
    bool isActive = false;
    if (connected && _deviceState != null) {
      if (label == l10n.t('ins') && _deviceState == DeviceState.keepWarm) {
        isActive = true;
      } else if (label == l10n.t('heat') &&
          _deviceState == DeviceState.heating) {
        isActive = true;
      } else if (label == l10n.t('timer') &&
          _deviceState == DeviceState.timing) {
        isActive = true;
      }
    }

    // 根据连接状态和激活状态确定颜色
    final color =
        !connected ? Colors.grey : (isActive ? Colors.orange : AppColors.black);

    // 根据按钮类型和激活状态选择图片
    Widget buttonIcon;
    if (label == l10n.t('ins')) {
      buttonIcon = isActive
          ? Assets.device.images.devInsSelect.image(width: 48, height: 47)
          : Assets.device.images.devIns.image(width: 48, height: 47);
    } else if (label == l10n.t('heat')) {
      buttonIcon = isActive
          ? Assets.device.images.devHeatSelect.image(width: 44, height: 53)
          : Assets.device.images.devHeat.image(width: 44, height: 53);
    } else if (label == l10n.t('timer')) {
      buttonIcon = isActive
          ? Assets.device.images.devTimerSelect.image(width: 41, height: 44)
          : Assets.device.images.devTimer.image(width: 41, height: 44);
    } else {
      buttonIcon = icon;
    }

    return GestureDetector(
      onTap: () async {
        if (!connected) return;

        // 检查设备是否已关机
        if (_isPoweredOff) {
          AppToast.show(context, l10n.t('device_is_powered_off'));
          return;
        }

        if (label == l10n.t('ins')) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const KeepWarmPage()),
          );
        } else if (label == l10n.t('heat')) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HeatPage()),
          );
        } else if (label == l10n.t('timer')) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HeatingTimePage()),
          );
        }
      },
      child: Container(
        width: 64,
        height: 145,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(37),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 58,
              child: Center(child: buttonIcon),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 28),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
