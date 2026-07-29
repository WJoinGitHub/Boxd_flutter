import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';
import 'api_client.dart';

/// 产品列表：启动拉取、本地缓存，按蓝牙名匹配 `product_name`。
class ProductService extends ChangeNotifier {
  ProductService._();
  static final ProductService instance = ProductService._();

  static const String _cacheKey = 'products_cache_v2';

  List<ProductModel> _products = [];
  bool _loadedFromLocal = false;
  bool _refreshing = false;

  List<ProductModel> get products => List.unmodifiable(_products);

  /// 先读本地缓存，再请求接口；失败则保留本地数据。
  Future<void> bootstrap() async {
    await loadFromLocal();
    await refreshFromNetwork();
  }

  Future<void> loadFromLocal() async {
    if (_loadedFromLocal) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null || raw.isEmpty) {
        _loadedFromLocal = true;
        return;
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _loadedFromLocal = true;
        return;
      }
      _products = decoded
          .whereType<Map>()
          .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      _loadedFromLocal = true;
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[PRODUCT] 本地缓存已加载: ${_products.length} 条');
      }
    } catch (e) {
      _loadedFromLocal = true;
      if (kDebugMode) {
        debugPrint('[PRODUCT] 读取本地缓存失败: $e');
      }
    }
  }

  Future<void> refreshFromNetwork() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final result = await ApiClient.getProducts();
      if (kDebugMode) {
        debugPrint('[PRODUCT] 接口返回: $result');
      }
      final code = result['code'];
      final ok = code == 200 || code == 0;
      if (!ok || result['data'] == null) return;

      final data = result['data'];
      if (data is! List) return;

      final list = data
          .whereType<Map>()
          .map((e) => ProductModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (list.isEmpty) return;

      _products = list;
      await _saveToLocal(list);
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[PRODUCT] 已更新并缓存: ${_products.length} 条');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[PRODUCT] 拉取失败，沿用本地缓存: $e');
      }
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _saveToLocal(List<ProductModel> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  /// 蓝牙名包含某条 `ble_broadcast_name`（优先）则命中。
  /// 兼容：无广播名时回退 `product_code` / `product_name`。
  /// 优先更长关键字，避免短串误匹配。
  ProductModel? matchByBleName(String? blePlatformName) {
    final raw = blePlatformName?.trim();
    if (raw == null || raw.isEmpty || _products.isEmpty) return null;

    final name = raw.toUpperCase();

    ProductModel? matchBy(String Function(ProductModel p) keyOf) {
      final sorted = [..._products]..sort(
          (a, b) => keyOf(b).trim().length.compareTo(keyOf(a).trim().length),
        );
      for (final p in sorted) {
        final key = keyOf(p).trim().toUpperCase();
        if (key.isEmpty) continue;
        if (name.contains(key)) return p;
      }
      return null;
    }

    // 实际蓝牙广播段，例如 QIMI-B11-… 对应 ble_broadcast_name=B11
    return matchBy((p) => p.bleBroadcastName) ??
        matchBy((p) => p.productCode) ??
        matchBy((p) => p.productName);
  }

  /// App 展示用蓝牙名：若 `app_display_name` 与 `ble_broadcast_name` 不同，则替换广播段。
  /// 例如 `QIMI-B11-J00048` + (ble=B11, display=B16) → `QIMI-B16-J00048`。
  String displayNameForBle(String? bleOrDeviceName, {String? fallback}) {
    final raw = bleOrDeviceName?.trim() ?? '';
    if (raw.isEmpty) return fallback ?? '';

    final product = matchByBleName(raw);
    if (product == null) return raw;

    final broadcast = product.bleBroadcastName.trim();
    final display = product.appDisplayName.trim();
    if (display.isEmpty) return raw;

    // 优先用 ble_broadcast_name → app_display_name
    if (broadcast.isNotEmpty &&
        broadcast.toUpperCase() != display.toUpperCase()) {
      return _replaceIgnoreCase(raw, broadcast, display);
    }

    // 无 ble_broadcast_name 时，用 product_name → app_display_name
    final productName = product.productName.trim();
    if (productName.isNotEmpty &&
        productName.toUpperCase() != display.toUpperCase()) {
      return _replaceIgnoreCase(raw, productName, display);
    }

    return raw;
  }

  static String _replaceIgnoreCase(String source, String from, String to) {
    if (from.isEmpty) return source;
    final pattern = RegExp(RegExp.escape(from), caseSensitive: false);
    return source.replaceFirst(pattern, to);
  }
}
