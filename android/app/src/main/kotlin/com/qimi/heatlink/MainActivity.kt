package com.qimi.heatlink

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    MethodChannel(
      flutterEngine.dartExecutor.binaryMessenger,
      "com.qimi.heatlink/platform",
    ).setMethodCallHandler { call, result ->
      when (call.method) {
        "hasGooglePlayServices" -> result.success(hasGooglePlayServicesInstalled())
        else -> result.notImplemented()
      }
    }
  }

  private fun hasGooglePlayServicesInstalled(): Boolean {
    return try {
      packageManager.getPackageInfo("com.google.android.gms", 0)
      true
    } catch (_: Exception) {
      false
    }
  }

  override fun onResume() {
    super.onResume()
    clearNotificationBadge()
  }
}
