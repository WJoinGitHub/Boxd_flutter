package com.qimi.heatlink

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

  override fun onResume() {
    super.onResume()
    clearNotificationBadge()
  }
}
