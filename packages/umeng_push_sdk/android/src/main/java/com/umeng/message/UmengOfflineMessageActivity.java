package com.umeng.message;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;

import com.umeng.message.common.UPLog;
import com.umeng.message.entity.UMessage;

import java.util.Map;
import java.util.Set;

/**
 * 离线消息点击入口类
 */
public class UmengOfflineMessageActivity extends Activity {

    private static final String TAG = "UPush.OfflineMessage";

    private final UmengNotifyClick mNotificationClick = new UmengNotifyClick() {
        @Override
        public void onMessage(UMessage msg) {
            String body = msg.getRaw().toString();
            UPLog.d(TAG, "offline msg: " + body);
            UmengPushSdkPlugin.setOfflineMsg(msg);
            launchApp(msg);
            finish();
        }
    };

    @Override
    protected void onCreate(Bundle bundle) {
        super.onCreate(bundle);
        mNotificationClick.onCreate(this, getIntent());
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        mNotificationClick.onNewIntent(intent);
    }

    private void launchApp(UMessage msg) {
        try {
            String pkg = getPackageName();
            Intent intent = getPackageManager().getLaunchIntentForPackage(pkg);
            if (intent == null) {
                UPLog.e(TAG, "can't find launch activity:" + pkg);
                return;
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
            addMessageToIntent(intent, msg);
            startActivity(intent);
            UPLog.i(TAG, "start app: " + pkg);
        } catch (Throwable e) {
            UPLog.e(TAG, "start app fail:", e.getMessage());
        }
    }

    private void addMessageToIntent(Intent intent, UMessage msg) {
        if (intent == null || msg == null || msg.getExtra() == null) {
            return;
        }
        Set<Map.Entry<String, String>> entrySet = msg.getExtra().entrySet();
        for (Map.Entry<String, String> entry : entrySet) {
            String key = entry.getKey();
            String value = entry.getValue();
            if (key != null) {
                intent.putExtra(key, value);
            }
        }
    }
}
