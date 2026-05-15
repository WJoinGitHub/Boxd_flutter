import 'package:flutter/material.dart';

/// 供首页 [RouteAware] 订阅，在从子页面返回等场景收到 [RouteAware.didPopNext]。
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
