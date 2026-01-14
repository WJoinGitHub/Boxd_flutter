import 'dart:async';
import 'dart:io';
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

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  bool connected = false;
  int temperature = 0;
  int batteryLevel = 0;
  Map<String, dynamic>? deviceDetail;
  String temperatureUnit = '°C';
  List<Map<String, dynamic>> _devices = [];
  Map<String, dynamic>? _currentDevice;
  bool _wasLoggedIn = false;
  bool _isInitialized = false;
  DeviceState? _deviceState;
  int? _mealTime; // 设备工作结束时间（从00:00开始的总分钟数）
  Timer? _connectionCheckTimer;
  bool _isPoweredOff = false; // 设备是否已关机
  bool _isConnecting = false; // 是否正在连接设备

  final bleService = BleService();

  @override
  void initState() {
    super.initState();
    print("HomePage initState start");
    WidgetsBinding.instance.addObserver(this);
    _wasLoggedIn = UserService().isLoggedIn;
    _loadTemperatureUnit();
    _init();
    _isInitialized = true;

    // 注册401错误回调，用于清空设备列表
    UserService().onUnauthorized = () {
      if (mounted) {
        setState(() {
          _devices = [];
          _currentDevice = null;
          _wasLoggedIn = false;
        });
        print('[HOME] 401错误，已清空设备列表');
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

          // 更新结束时间（mealTime）
          if (status.mealTime != null) {
            _mealTime = status.mealTime;
            print('[HOME] 更新结束时间: $_mealTime 分钟（从00:00开始）');
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
            deviceDetail = null;
          }
        });
      }
    });
  }

  Future<void> _loadTemperatureUnit() async {
    final unit = await AppStorage.loadUnit();
    if (mounted) {
      setState(() => temperatureUnit = unit);
    }
  }

  Future<void> _init() async {
    await _autoLogin();
    // 登录后检查状态是否变化
    final isLoggedIn = UserService().isLoggedIn;
    if (!_wasLoggedIn && isLoggedIn) {
      print('[HOME] _init 检测到登录状态变化，更新 _wasLoggedIn');
      _wasLoggedIn = isLoggedIn;
    }
    await _autoConnect();
  }

  Future<void> _autoLogin() async {
    print('[HOME] 开始自动登录...');
    final hasToken = await UserService().loadFromLocal();
    print('[HOME] loadFromLocal 结果: $hasToken');
    if (hasToken) {
      // 只有在本地没有用户信息时才获取
      if (UserService().currentUser == null) {
        try {
          await UserService().fetchUserInfo();
          print('[HOME] 用户信息: ${UserService().currentUser?.email}');
        } catch (e) {
          print('[HOME] 获取用户信息失败: $e');
          // 如果获取用户信息失败（可能是401），确保UI更新
        }
      }
      print('[HOME] isLoggedIn: ${UserService().isLoggedIn}');
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _loadDevices() async {
    try {
      final result = await ApiClient.getDevices(page: 1, pageSize: 100);
      if (result['code'] == 200 && result['data'] != null) {
        final devices = List<Map<String, dynamic>>.from(result['data']);

        // 从本地匹配保存的设备名称
        final userId = UserService().currentUser?.userId;
        if (userId != null) {
          for (var device in devices) {
            final deviceUuid = device['device_uuid'] as String?;
            if (deviceUuid != null) {
              final localName =
                  await AppStorage.loadDeviceLocalName(userId, deviceUuid);
              if (localName != null && localName.isNotEmpty) {
                device['local_name'] = localName;
              }
            }
          }
        }

        if (mounted) {
          setState(() {
            _devices = devices;
            // 设置当前设备（优先使用已连接的设备，否则使用第一个）
            if (_currentDevice == null && devices.isNotEmpty) {
              _currentDevice = devices.first;
            }
          });
        }
      }
    } catch (e) {
      print('[HOME] 加载设备列表失败: $e');
    }
  }

  Future<void> _autoConnect() async {
    print('[HOME] 尝试自动连接...');
    // 只有在已登录状态下才加载设备列表
    if (!UserService().isLoggedIn) {
      print('[HOME] 未登录，跳过加载设备列表');
      return;
    }

    await _loadDevices();
    if (_devices.isEmpty) {
      print('[HOME] 没有绑定的设备');
      return;
    }

    // 取设备列表第一个设备，走用户点击连接设备的逻辑
    final firstDevice = _devices.first;
    print('[HOME] 自动连接第一个设备: ${firstDevice['device_uuid']}');
    await _connectToDevice(firstDevice);
  }

  /// 获取显示设备名（如果有多个设备，添加序列号）
  String _getDisplayDeviceName() {
    if (_currentDevice == null) return 'HeatLink';

    // 优先使用本地保存的名称
    final localName = _currentDevice!['local_name'] as String?;
    final deviceName =
        localName ?? (_currentDevice!['device_name'] as String? ?? 'HeatLink');

    if (_devices.length > 1) {
      // 找到当前设备在列表中的索引
      final index = _devices.indexWhere(
        (device) => device['device_uuid'] == _currentDevice!['device_uuid'],
      );
      if (index >= 0) {
        return '$deviceName ${index + 1}';
      }
    }
    return deviceName;
  }

  Future<void> _showEditDeviceNameDialog() async {
    if (_currentDevice == null) return;

    final currentName =
        _getDisplayDeviceName().replaceAll(RegExp(r' \d+$'), ''); // 移除序列号
    final controller = TextEditingController(text: currentName);

    final l10n = AppLocalizations.of(context);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      final userId = UserService().currentUser?.userId;
      final deviceUuid = _currentDevice!['device_uuid'] as String?;

      if (userId != null && deviceUuid != null) {
        await AppStorage.saveDeviceLocalName(userId, deviceUuid, newName);
        _currentDevice!['local_name'] = newName;
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('device_name_saved'))),
          );
        }
      }
    }
  }

  Future<void> _showDeviceSelector() async {
    if (_devices.isEmpty) return;

    final selectedDevice = await showModalBottomSheet<Map<String, dynamic>>(
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
                final deviceUuid = device['device_uuid'] as String? ?? '';
                final deviceName =
                    device['device_name'] as String? ?? 'Unknown Device';
                // 如果有多个设备，添加序列号
                final displayName = _devices.length > 1
                    ? '$deviceName ${index + 1}'
                    : deviceName;
                final isCurrent = _currentDevice?['device_uuid'] == deviceUuid;
                final isDeviceConnected = connected && isCurrent;

                return ListTile(
                  title: Text(displayName),
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
        selectedDevice['device_uuid'] != _currentDevice?['device_uuid']) {
      await _switchDevice(selectedDevice);
    }
  }

  Future<void> _switchDevice(Map<String, dynamic> newDevice) async {
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

  Future<void> _connectToDevice(Map<String, dynamic> device) async {
    if (mounted) {
      setState(() => _isConnecting = true);
    }

    try {
      final deviceUuid = device['device_uuid'] as String;
      print('[HOME] 连接设备: $deviceUuid');

      final connectedDevices = await FlutterBluePlus.connectedSystemDevices;
      BluetoothDevice? targetDevice;

      for (var d in connectedDevices) {
        // 尝试通过UUID匹配
        final currentUuid = Platform.isAndroid
            ? d.remoteId.str.replaceAll(':', '').toUpperCase()
            : d.remoteId.str.replaceAll('-', '').toUpperCase();
        if (currentUuid == deviceUuid) {
          targetDevice = d;
          break;
        }
      }

      if (targetDevice == null) {
        print('[HOME] 开始扫描设备...');
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
        await for (var results in FlutterBluePlus.scanResults) {
          for (var r in results) {
            // 尝试通过UUID匹配
            final currentUuid = Platform.isAndroid
                ? r.device.remoteId.str.replaceAll(':', '').toUpperCase()
                : r.device.remoteId.str.replaceAll('-', '').toUpperCase();
            if (currentUuid == deviceUuid) {
              targetDevice = r.device;
              break;
            }
            // 尝试通过设备名称匹配
            final deviceName = device['device_name'] as String? ?? '';
            if (deviceName.isNotEmpty && r.device.platformName == deviceName) {
              targetDevice = r.device;
              break;
            }
          }
          if (targetDevice != null) break;
        }
        await FlutterBluePlus.stopScan();
      }

      if (targetDevice != null && mounted) {
        final success = await bleService.connect(targetDevice, skipBind: true);
        if (success && mounted) {
          setState(() => connected = true);
          print('[HOME] 设备连接成功');
          // 获取设备详情
          try {
            final detail = await ApiClient.getDeviceDetail(deviceUuid);
            if (detail['code'] == 200 && detail['data'] != null && mounted) {
              setState(() => deviceDetail = detail['data']);
            }
          } catch (e) {
            print('[HOME] 获取设备详情失败: $e');
          }
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context).t('device_not_found'))),
        );
      }
    } catch (e) {
      print('[HOME] 连接设备失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context).t('failed_to_connect')}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  void dispose() {
    _connectionCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    bleService.dispose();
    // 移除401错误回调
    UserService().onUnauthorized = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    }
  }

  Future<void> _checkLoginStatusAndRefresh() async {
    final isLoggedIn = UserService().isLoggedIn;
    print(
        '[HOME] _checkLoginStatusAndRefresh - _wasLoggedIn: $_wasLoggedIn, isLoggedIn: $isLoggedIn');

    // 如果从未登录变为已登录，刷新设备列表
    if (!_wasLoggedIn && isLoggedIn) {
      print('[HOME] 检测到登录状态变化，刷新设备列表');
      _wasLoggedIn = isLoggedIn;
      await _loadDevices();
      await _autoConnect();
      if (mounted) {
        setState(() {});
      }
    } else if (_wasLoggedIn != isLoggedIn) {
      // 更新状态，但不刷新（登出情况）
      print('[HOME] 登录状态变化（登出）');
      _wasLoggedIn = isLoggedIn;
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
                          // 顶部标题与头像
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "QIMI",
                                    style: TextStyle(
                                      fontSize: 17,
                                      color: AppColors.gray4,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: _devices.length > 1
                                            ? _showDeviceSelector
                                            : null,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _getDisplayDeviceName(),
                                              style: const TextStyle(
                                                fontSize: 25,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.black,
                                              ),
                                            ),
                                            if (_devices.length > 1) ...[
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.arrow_drop_down,
                                                color: Colors.black,
                                                size: 20,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (_currentDevice != null) ...[
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: _showEditDeviceNameDialog,
                                          child: Icon(
                                            Icons.edit,
                                            size: 18,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  // 已登录且未连接且有设备时，显示连接按钮
                                  if (!connected &&
                                      UserService().isLoggedIn &&
                                      _currentDevice != null) ...[
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _isConnecting
                                          ? null
                                          : () async {
                                              if (_currentDevice != null) {
                                                await _connectToDevice(
                                                    _currentDevice!);
                                              }
                                            },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            l10n.t('connect_device'),
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: _isConnecting
                                                  ? Colors.grey
                                                  : AppColors.orange,
                                              fontWeight: FontWeight.w500,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                          ),
                                          if (_isConnecting) ...[
                                            const SizedBox(width: 8),
                                            SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        AppColors.orange),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  if (UserService().isLoggedIn) {
                                    final result =
                                        await Navigator.of(context).push(
                                      PageRouteBuilder(
                                        pageBuilder: (_, __, ___) =>
                                            SettingsPage(
                                                deviceDetail: deviceDetail),
                                      ),
                                    );
                                    // 如果从设置页返回时设备列表有变化，刷新设备列表
                                    if (result == true && mounted) {
                                      print('[HOME] 设备列表已变化，刷新列表');
                                      await _loadDevices();
                                    }
                                  } else {
                                    Navigator.of(context).push(
                                      PageRouteBuilder(
                                        fullscreenDialog: true,
                                        pageBuilder: (_, __, ___) =>
                                            const EmailLoginPage(),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  elevation: 0,
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(33, 33),
                                  shape: const CircleBorder(),
                                ),
                                child: Center(
                                  child: Assets.user.images.userAvatar.image(
                                    width: 33,
                                    height: 33,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 2),

                          // 连接状态
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (connected)
                                    Icon(
                                      Icons.circle,
                                      color: AppColors.green,
                                      size: 13,
                                    ),
                                  const SizedBox(width: 5),
                                  Text(
                                    connected
                                        ? l10n.t('connected')
                                        : l10n.t('connect_your_lunch_box'),
                                    style: TextStyle(
                                      fontSize: connected ? 20 : 13,
                                      color: connected
                                          ? AppColors.green
                                          : Colors.black54,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                              if (!connected)
                                ElevatedButton(
                                  onPressed: () async {
                                    if (!UserService().isLoggedIn) {
                                      await Navigator.of(context).push(
                                        PageRouteBuilder(
                                          fullscreenDialog: true,
                                          pageBuilder: (_, __, ___) =>
                                              const EmailLoginPage(),
                                        ),
                                      );
                                      if (!mounted || !UserService().isLoggedIn)
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
                                      setState(() =>
                                          connected = bleService.isConnected);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(29, 27),
                                    shape: const CircleBorder(),
                                  ),
                                  child: Center(
                                    child: Assets.home.images.addDevice.image(
                                      width: 21,
                                      height: 21,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // 🔥 新增：左右图片区域
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 左边：状态图片 + 模式文案 + 温度（仅在连接时显示）
                          if (connected)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // 状态图片
                                _getModeImage(),
                                const SizedBox(height: 20),
                                // 模式文案
                                Text(
                                  _getModeText(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                // 温度显示（类似keepwarmpage样式）
                                Row(
                                  children: [
                                    Assets.device.images.temperature.image(
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: const Color(0xFF7F8489),
                                              width: 1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          temperatureUnit,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                // 结束时间显示（仅在保温、加热、定时状态时显示）
                                if (_shouldShowEndTime() &&
                                    _getEndTimeText() != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Device work ends at ${_getEndTimeText()}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          else
                            const SizedBox.shrink(),

                          // 右边设备图片 + 电量
                          Column(
                            children: [
                              Assets.home.images.homeDevice.image(
                                width: 150,
                                fit: BoxFit.contain,
                              ),
                              if (connected)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      batteryLevel > 20
                                          ? Icons.battery_std
                                          : Icons.battery_alert,
                                      color: batteryLevel > 20
                                          ? Colors.green
                                          : Colors.red,
                                      size: 20,
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
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 0, vertical: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 33),

                          // 三个功能按钮
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                ),
              ),
            ),
            // Banner 贴底 / 电源开关
            if (connected)
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () async {
                    if (_isPoweredOff) {
                      // 开机
                      final success = await bleService.startDevice();
                      if (mounted) {
                        final l10n = AppLocalizations.of(context);
                        if (success) {
                          setState(() => _isPoweredOff = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.t('device_powered_on'))),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.t('failed_to_power_on'))),
                          );
                        }
                      }
                    } else {
                      // 关机
                      final success = await bleService.stopDevice();
                      if (mounted) {
                        final l10n = AppLocalizations.of(context);
                        if (success) {
                          setState(() => _isPoweredOff = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.t('device_powered_off'))),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.t('failed_to_power_off'))),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPoweredOff ? Colors.green : Colors.red,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              )
            else
              Assets.home.images.homeBanner.image(
                width: double.infinity,
                fit: BoxFit.contain,
              ),
          ],
        ),
      ),
    );
  }

  /// 切换温度单位
  Future<void> _toggleTemperatureUnit() async {
    if (!connected) return;

    final newUnit = temperatureUnit == '°C' ? '°F' : '°C';
    await AppStorage.saveUnit(newUnit);
    setState(() => temperatureUnit = newUnit);

    // 发送切换温度单位命令
    await bleService.syncTime();
  }

  /// 获取显示温度（根据单位转换）
  int _getDisplayTemperature() {
    if (temperatureUnit == '°F') {
      // 摄氏度转华氏度: F = C * 9/5 + 32
      return (temperature * 9 / 5 + 32).round();
    }
    return temperature;
  }

  /// 获取结束时间显示文本（将分钟数转换为时:分格式）
  String? _getEndTimeText() {
    if (_mealTime == null) return null;

    // mealTime 是从00:00开始的总分钟数
    final hours = _mealTime! ~/ 60;
    final minutes = _mealTime! % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  /// 是否应该显示结束时间（仅在定时状态时显示）
  bool _shouldShowEndTime() {
    if (_deviceState == null) return false;
    return _deviceState == DeviceState.timing;
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

    return GestureDetector(
      onTap: () async {
        if (!connected) return;

        // 检查设备是否已关机
        if (_isPoweredOff) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.t('device_is_powered_off'))),
          );
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
          children: [
            const SizedBox(height: 20),
            SizedBox(
              height: 58,
              child: Center(child: icon),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 28),
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
