package com.umeng.message.demo;

import android.content.Context;
import android.util.Log;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
//import io.flutter.plugin.common.PluginRegistry.Registrar;

public class DemoHelperPlugin implements FlutterPlugin, MethodCallHandler {
    private static final String TAG = "UPushHelper";

    private MethodChannel mChannel;

    private Context mContext;

    @Override
    public void onAttachedToEngine(FlutterPluginBinding flutterPluginBinding) {
        mContext = flutterPluginBinding.getApplicationContext();
        mChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "u-push-helper");
        mChannel.setMethodCallHandler(this);
    }

//    public static void registerWith(Registrar registrar) {
//        MethodChannel channel = new MethodChannel(registrar.messenger(), "u-push-helper");
//        DemoHelperPlugin plugin = new DemoHelperPlugin();
//        plugin.mContext = registrar.context();
//        plugin.mChannel = channel;
//        channel.setMethodCallHandler(plugin);
//    }

    @Override
    public void onMethodCall(MethodCall call, Result result) {
        try {
            if ("agree".equals(call.method)) {
                mContext.getSharedPreferences("my_prefs", 0).edit().putBoolean("key_agreed", true).apply();
                Log.i(TAG, "agreed");
                result.success(null);
                return;
            }
            if ("isAgreed".equals(call.method)) {
                boolean agreed = mContext.getSharedPreferences("my_prefs", 0).getBoolean("key_agreed", false);
                result.success(agreed);
                return;
            }
            result.notImplemented();
        } catch (Exception e) {
            Log.e(TAG, "Exception:" + e.getMessage());
        }
    }

    @Override
    public void onDetachedFromEngine(FlutterPluginBinding binding) {
    }

}
