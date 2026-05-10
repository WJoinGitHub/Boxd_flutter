package com.umeng.umeng_common_sdk_example;

import android.os.Bundle;

import io.flutter.embedding.android.FlutterActivity;
import com.umeng.analytics.MobclickAgent;

public class MainActivity extends FlutterActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        android.util.Log.i("UMLog", "onCreate@MainActivity");
    }
}
