package com.umeng.message;

import android.annotation.SuppressLint;
import android.content.Context;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.Looper;
import android.text.TextUtils;

import com.umeng.commonsdk.UMConfigure;
import com.umeng.message.api.UPushAliasCallback;
import com.umeng.message.api.UPushRegisterCallback;
import com.umeng.message.api.UPushSettingCallback;
import com.umeng.message.api.UPushTagCallback;
import com.umeng.message.common.UPLog;
import com.umeng.message.common.inter.ITagManager;
import com.umeng.message.entity.UMessage;

import org.android.agoo.honor.HonorRegister;
import org.android.agoo.huawei.HuaWeiRegister;
import org.android.agoo.mezu.MeizuRegister;
import org.android.agoo.oppo.OppoRegister;
import org.android.agoo.vivo.VivoRegister;
import org.android.agoo.xiaomi.MiPushRegistar;

import java.util.Collections;
import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * 推送Flutter插件类
 */
public class UmengPushSdkPlugin implements FlutterPlugin, MethodCallHandler {
    private static final String TAG = "Flutter";

    private Context mContext;
    private MethodChannel mChannel;

    private static String sOfflineMsgCache;

    public static void setOfflineMsg(final UMessage msg) {
        if (msg == null) {
            return;
        }
        final UmengPushSdkPlugin plugin = getInstance();
        if (plugin != null) {
            plugin.mHandler.post(new Runnable() {
                @Override
                public void run() {
                    try {
                        if (plugin.mChannel != null) {
                            plugin.mChannel.invokeMethod("onNotificationOpen", msg.getRaw().toString());
                        }
                    } catch (Throwable e) {
                        e.printStackTrace();
                    }
                }
            });
            return;
        }
        sOfflineMsgCache = msg.getRaw().toString();
    }

    @SuppressLint("StaticFieldLeak")
    private static UmengPushSdkPlugin sInstance;

    public static UmengPushSdkPlugin getInstance() {
        return sInstance;
    }

    public UmengPushSdkPlugin() {
        sInstance = this;
    }

    @Override
    public void onAttachedToEngine(FlutterPluginBinding flutterPluginBinding) {
        UPLog.i(TAG, "onAttachedToEngine");
        mContext = flutterPluginBinding.getApplicationContext();
        mChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "u-push");
        mChannel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
        UPLog.i(TAG, "onDetachedFromEngine");
        mChannel = null;
    }

//    public static void registerWith(Registrar registrar) {
//        MethodChannel channel = new MethodChannel(registrar.messenger(), "u-push");
//        UmengPushSdkPlugin plugin = new UmengPushSdkPlugin();
//        plugin.mContext = registrar.context();
//        plugin.mChannel = channel;
//        channel.setMethodCallHandler(plugin);
//    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        try {
            if (!pushMethodCall(call, result)) {
                result.notImplemented();
            }
        } catch (Exception e) {
            UPLog.e(TAG, "Exception:" + e.getMessage());
        }
    }

    private boolean pushMethodCall(MethodCall call, Result result) {
        String method = call.method;
        if ("setLogEnable".equals(method)) {
            Boolean enable = call.arguments();
            if (enable != null) {
                UMConfigure.setLogEnabled(enable);
            }
            executeOnMain(result, null);
            return true;
        }
        if ("register".equals(method)) {
            register(result);
            return true;
        }
        if ("getDeviceToken".equals(method)) {
            getDeviceToken(result);
            return true;
        }
        if ("enable".equals(method)) {
            Boolean enable = call.arguments();
            if (enable != null) {
                setPushEnable(enable, result);
            }
            return true;
        }
        if ("setAlias".equals(method)) {
            setAlias(call, result);
            return true;
        }
        if ("addAlias".equals(method)) {
            addAlias(call, result);
            return true;
        }
        if ("removeAlias".equals(method)) {
            removeAlias(call, result);
            return true;
        }
        if ("addTag".equals(method)) {
            List<String> tags = call.arguments();
            if (tags != null) {
                addTags(tags, result);
            }
            return true;
        }
        if ("removeTag".equals(method)) {
            List<String> tags = call.arguments();
            if (tags != null) {
                removeTags(tags, result);
            }
            return true;
        }
        if ("getTags".equals(method)) {
            getTags(result);
            return true;
        }
        if ("setBadge".equals(method)) {
            Integer number = call.arguments();
            if (number != null) {
                setBadge(number, result);
            }
        }
        return false;
    }

    private void getTags(final Result result) {
        PushAgent.getInstance(mContext).getTagManager().getTags(new UPushTagCallback<List<String>>() {
            @Override
            public void onMessage(final boolean b, final List<String> list) {
                if (b) {
                    executeOnMain(result, list);
                } else {
                    executeOnMain(result, Collections.emptyList());
                }
            }
        });
    }

    private void removeTags(List<String> tags, final Result result) {
        String[] tagArray = new String[tags.size()];
        tags.toArray(tagArray);
        PushAgent.getInstance(mContext).getTagManager().deleteTags(new UPushTagCallback<ITagManager.Result>() {
            @Override
            public void onMessage(final boolean b, ITagManager.Result ret) {
                executeOnMain(result, b);
            }
        }, tagArray);
    }

    private void addTags(List<String> tags, final Result result) {
        String[] tagArray = new String[tags.size()];
        tags.toArray(tagArray);
        PushAgent.getInstance(mContext).getTagManager().addTags(new UPushTagCallback<ITagManager.Result>() {
            @Override
            public void onMessage(final boolean b, ITagManager.Result ret) {
                executeOnMain(result, b);
            }
        }, tagArray);
    }

    private void removeAlias(MethodCall call, final Result result) {
        String alias = getParam(call, result, "alias");
        String type = getParam(call, result, "type");
        PushAgent.getInstance(mContext).deleteAlias(alias, type, new UPushAliasCallback() {
            @Override
            public void onMessage(final boolean b, String s) {
                UPLog.i(TAG, "onMessage:" + b + " s:" + s);
                executeOnMain(result, b);
            }
        });
    }

    private void addAlias(MethodCall call, final Result result) {
        String alias = getParam(call, result, "alias");
        String type = getParam(call, result, "type");
        PushAgent.getInstance(mContext).addAlias(alias, type, new UPushAliasCallback() {
            @Override
            public void onMessage(boolean b, String s) {
                UPLog.i(TAG, "onMessage:" + b + " s:" + s);
                executeOnMain(result, b);
            }
        });
    }

    private void setAlias(MethodCall call, final Result result) {
        String alias = getParam(call, result, "alias");
        String type = getParam(call, result, "type");
        PushAgent.getInstance(mContext).setAlias(alias, type, new UPushAliasCallback() {
            @Override
            public void onMessage(final boolean b, String s) {
                UPLog.i(TAG, "onMessage:" + b + " s:" + s);
                executeOnMain(result, b);
            }
        });
    }

    private void setPushEnable(final boolean enable, Result result) {
        UPushSettingCallback callback = new UPushSettingCallback() {
            @Override
            public void onSuccess() {
                UPLog.i(TAG, "setPushEnable success:" + enable);
            }

            @Override
            public void onFailure(String s, String s1) {
                UPLog.i(TAG, "setPushEnable failure:" + enable);
            }
        };
        if (enable) {
            PushAgent.getInstance(mContext).enable(callback);
        } else {
            PushAgent.getInstance(mContext).disable(callback);
        }
        executeOnMain(result, null);
    }

    private void getDeviceToken(Result result) {
        result.success(PushAgent.getInstance(mContext).getRegistrationId());
    }

    private void register(final Result result) {
        UMConfigure.init(mContext, null, null, UMConfigure.DEVICE_TYPE_PHONE,null);

        PushAgent api = PushAgent.getInstance(mContext);
        api.setDisplayNotificationNumber(0);

        UmengMessageHandler messageHandler = new UmengMessageHandler() {
            @Override
            public void dealWithCustomMessage(Context context, final UMessage uMessage) {
                super.dealWithCustomMessage(context, uMessage);
                UPLog.i(TAG, "dealWithCustomMessage");
                mHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            if (mChannel != null) {
                                mChannel.invokeMethod("onMessage", uMessage.getRaw().toString());
                            }
                        } catch (Throwable e) {
                            e.printStackTrace();
                        }
                    }
                });
            }

            @Override
            public void dealWithNotificationMessage(Context context, final UMessage uMessage) {
                super.dealWithNotificationMessage(context, uMessage);
                mHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            if (mChannel != null) {
                                mChannel.invokeMethod("onNotificationReceive", uMessage.getRaw().toString());
                            }
                        } catch (Throwable e) {
                            e.printStackTrace();
                        }
                    }
                });
            }
        };
        api.setMessageHandler(messageHandler);
        UmengNotificationClickHandler clickHandler = new UmengNotificationClickHandler() {
            @Override
            public void handleMessage(Context context, final UMessage uMessage) {
                super.handleMessage(context, uMessage);
                if (uMessage.dismiss) {
                    return;
                }
                mHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            if (mChannel != null) {
                                mChannel.invokeMethod("onNotificationOpen", uMessage.getRaw().toString());
                            } else {
                                sOfflineMsgCache = uMessage.getRaw().toString();
                            }
                        } catch (Throwable e) {
                            e.printStackTrace();
                        }
                    }
                });
            }
        };
        api.setNotificationClickHandler(clickHandler);
        api.register(new UPushRegisterCallback() {
            @Override
            public void onSuccess(final String deviceToken) {
                UPLog.i(TAG, "register success deviceToken:" + deviceToken);
                mHandler.post(new Runnable() {
                    @Override
                    public void run() {
                        try {
                            if (mChannel != null) {
                                mChannel.invokeMethod("onToken", deviceToken);
                            }
                        } catch (Throwable e) {
                            e.printStackTrace();
                        }
                    }
                });

                try {
                    ApplicationInfo appInfo = mContext.getPackageManager().getApplicationInfo(mContext.getPackageName(), PackageManager.GET_META_DATA);

                    try {
                        String xmAppId = appInfo.metaData.getString(META_DATA.XM_APP_ID).replace("appid=", "");
                        String xmAppKey = appInfo.metaData.getString(META_DATA.XM_APP_KEY).replace("appkey=", "");
                        MiPushRegistar.register(mContext, xmAppId, xmAppKey);
                    } catch (Throwable e) {
                        UPLog.e(TAG, "xiaomi register err:", e.getMessage());
                    }

                    try {
                        String mzAppId = appInfo.metaData.getString(META_DATA.MZ_APP_ID).replace("appid=", "");
                        String mzAppKey = appInfo.metaData.getString(META_DATA.MZ_APP_KEY).replace("appkey=", "");
                        MeizuRegister.register(mContext, mzAppId, mzAppKey);
                    } catch (Throwable e) {
                        UPLog.e(TAG, "mz register err:", e.getMessage());
                    }

                    try {
                        String oppoAppKey = appInfo.metaData.getString(META_DATA.OP_APP_KEY);
                        String oppoAppSecret = appInfo.metaData.getString(META_DATA.OP_APP_SECRET);
                        OppoRegister.register(mContext, oppoAppKey, oppoAppSecret);
                    } catch (Throwable e) {
                        UPLog.e(TAG, "oppo register err:", e.getMessage());
                    }

                    try {
                        VivoRegister.register(mContext);
                    } catch (Throwable e) {
                        UPLog.e(TAG, "vivo register err:", e.getMessage());
                    }

                    try {
                        HuaWeiRegister.register(mContext);
                    } catch (Throwable e) {
                        UPLog.e(TAG, "huawei register err:", e.getMessage());
                    }

                    try {
                        HonorRegister.register(mContext);
                    } catch (Throwable e) {
                        UPLog.e(TAG, "honor register err:", e.getMessage());
                    }

                } catch (Throwable e) {
                    UPLog.e(TAG, "register err:", e.getMessage());
                }
            }

            @Override
            public void onFailure(String s, String s1) {
                UPLog.i(TAG, "register failure s:" + s + " s1:" + s1);
            }
        });
        executeOnMain(result, null);
        if (!TextUtils.isEmpty(sOfflineMsgCache)) {
            final String cacheMsg = sOfflineMsgCache;
            sInstance.mHandler.post(new Runnable() {
                @Override
                public void run() {
                    try {
                        if (sInstance.mChannel != null) {
                            sInstance.mChannel.invokeMethod("onNotificationOpen", cacheMsg);
                        }
                    } catch (Throwable e) {
                        e.printStackTrace();
                    }
                }
            });
            sOfflineMsgCache = null;
        }
    }

    private final Handler mHandler = new Handler(Looper.getMainLooper());

    private void executeOnMain(final Result result, final Object param) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            try {
                result.success(param);
            } catch (Throwable throwable) {
                throwable.printStackTrace();
            }
            return;
        }
        mHandler.post(new Runnable() {
            @Override
            public void run() {
                try {
                    result.success(param);
                } catch (Throwable throwable) {
                    throwable.printStackTrace();
                }
            }
        });
    }

    public static <T> T getParam(MethodCall methodCall, MethodChannel.Result result, String param) {
        T value = methodCall.argument(param);
        if (value == null) {
            result.error("missing param", "cannot find param:" + param, 1);
        }
        return value;
    }

    private static class META_DATA {
        public static final String XM_APP_ID = "org.android.agoo.xiaomi.app_id";
        public static final String XM_APP_KEY = "org.android.agoo.xiaomi.app_key";
        public static final String MZ_APP_ID = "org.android.agoo.meizu.app_id";
        public static final String MZ_APP_KEY = "org.android.agoo.meizu.app_key";
        public static final String OP_APP_KEY = "org.android.agoo.oppo.app_key";
        public static final String OP_APP_SECRET = "org.android.agoo.oppo.app_secret";
    }

    //支持华为、荣耀、vivo、OPPO（需申请）等
    private void setBadge(int number, Result result) {
        PushAgent.getInstance(mContext).setBadgeNum(number);
        executeOnMain(result, true);
    }
    //-----  PUSH END -----
}
