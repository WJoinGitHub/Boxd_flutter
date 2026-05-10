package com.umeng.umeng_common_sdk_example;

import android.util.Log;
import io.flutter.app.FlutterApplication;
import com.umeng.commonsdk.UMConfigure;

public class MyApp extends FlutterApplication {
	@Override
	public void onCreate() {
		super.onCreate();
		Log.i("UMENG", "--->>> FlutterApplication: onCreate enter");
		UMConfigure.setLogEnabled(true);
		UMConfigure.preInit(this,"5e3f96f3cb23d2a070000048","Umeng");

	}
}
