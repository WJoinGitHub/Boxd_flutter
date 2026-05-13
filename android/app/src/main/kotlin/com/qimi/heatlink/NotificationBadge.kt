package com.qimi.heatlink

import android.app.Notification
import android.app.NotificationManager
import android.content.Context
import android.os.Build

/**
 * 尽量清除桌面图标角标，同时保留通知栏里的通知。
 *
 * - **Android 7.0 (API 24)+**：对每条已展示的通知用 [Notification.Builder.recoverBuilder]
 *   重发为无角标样式（`number = 0`；API 26+ 再设 `BADGE_ICON_NONE`）。
 * - **更低版本**：系统能力有限，不做处理（避免 [NotificationManager.cancelAll] 清掉列表）。
 */
internal fun Context.clearNotificationBadge() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
        return
    }
    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    val active = nm.activeNotifications
    for (sbn in active) {
        try {
            val recovered = Notification.Builder.recoverBuilder(this, sbn.notification)
            recovered.setNumber(0)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                recovered.setBadgeIconType(Notification.BADGE_ICON_NONE)
            }
            val updated = recovered.build()
            val tag = sbn.tag
            if (tag != null) {
                nm.notify(tag, sbn.id, updated)
            } else {
                nm.notify(sbn.id, updated)
            }
        } catch (_: RuntimeException) {
        } catch (_: Exception) {
        }
    }
}
