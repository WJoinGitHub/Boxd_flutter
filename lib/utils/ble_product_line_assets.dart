import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/services/product_service.dart';

/// 首页右侧大设备图：按蓝牙名匹配产品 `product_name` → `home_image_url`，否则本地 B14 兜底。
Widget homeDeviceHeroImageForBleName(
  String? blePlatformName, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
}) {
  return ListenableBuilder(
    listenable: ProductService.instance,
    builder: (context, _) {
      final url = ProductService.instance
          .matchByBleName(blePlatformName)
          ?.homeImageUrl
          .trim();
      if (url != null && url.isNotEmpty) {
        return Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _homeB14(
            width: width,
            height: height,
            fit: fit,
          ),
        );
      }
      return _homeB14(width: width, height: height, fit: fit);
    },
  );
}

/// 连接流程等处的设备图：按蓝牙名匹配 `connect_image_url`，否则本地 B14 兜底。
Widget devConnectImageForBleName(
  String? blePlatformName, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.contain,
}) {
  return ListenableBuilder(
    listenable: ProductService.instance,
    builder: (context, _) {
      final url = ProductService.instance
          .matchByBleName(blePlatformName)
          ?.connectImageUrl
          .trim();
      if (url != null && url.isNotEmpty) {
        return Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => _connectB14(
            width: width,
            height: height,
            fit: fit,
          ),
        );
      }
      return _connectB14(width: width, height: height, fit: fit);
    },
  );
}

Widget _homeB14({double? width, double? height, BoxFit fit = BoxFit.contain}) {
  return Assets.home.images.homeDeviceB14.image(
    width: width,
    height: height,
    fit: fit,
  );
}

Widget _connectB14({double? width, double? height, BoxFit fit = BoxFit.contain}) {
  return Assets.device.images.devConnectB14.image(
    width: width,
    height: height,
    fit: fit,
  );
}
