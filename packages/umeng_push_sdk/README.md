# 友盟推送SDK插件 Flutter
## 集成
在工程 pubspec.yaml 中加入 dependencies

```
dependencies: 
    umeng_push_sdk: ^2.4.0
```

## 配置

创建应用请参考：https://developer.umeng.com/docs/67966/detail/99884

### Android

在 `/android/app/build.gradle` 中添加下列代码：

```groovy
android {
  defaultConfig {
    applicationId "您的应用包名"

    ndk {
        abiFilters 'armeabi', 'armeabi-v7a', 'arm64-v8a'
    }

    manifestPlaceholders = [
            UMENG_APPKEY: '您申请的appkey',
            UMENG_MESSAGE_SECRET: '您申请的message secret',
            UMENG_CHANNEL: '您的应用发布渠道',

            HUAWEI_APP_ID: '您申请的华为通道appid',

            HONOR_APP_ID: '您申请的荣耀通道appid',

            XIAOMI_APP_ID: '您申请的小米通道appid',
            XIAOMI_APP_KEY: '您申请的小米通道appkey',

            OPPO_APP_KEY: '您申请的OPPO通道appkey',
            OPPO_APP_SECRET: '您申请的OPPO通道app secret',

            VIVO_APP_ID: '您申请的VIVO通道appid',
            VIVO_APP_KEY: '您申请的VIVO通道appkey',

            MEIZU_APP_ID: '您申请的魅族通道appid',
            MEIZU_APP_KEY: '您申请的魅族通道appkey',
    ]
  }

}
```

厂商消息下发时，Activity路径传入：com.umeng.message.UmengOfflineMessageActivity

### iOS

证书配置请参考文档：https://developer.umeng.com/docs/67966/detail/66748

AppDelegate.m中需要进行的配置：

1. didFinishLaunchingWithOptions方法中设置消息代理

```oc
@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [GeneratedPluginRegistrant registerWithRegistry:self];
    [UNUserNotificationCenter currentNotificationCenter].delegate=self;
    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}
```

2. 处理willPresentNotification方法回调

```oc
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {

    NSDictionary * userInfo = notification.request.content.userInfo;

    [UmengPushSdkPlugin didReceiveUMessage:userInfo];
    if ([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [UMessage setAutoAlert:NO];
        //应用处于前台时的远程推送接收
        //必须加这句代码
        [UMessage didReceiveRemoteNotification:userInfo];
    } else {
        //应用处于前台时的本地推送接收
    }

    // 控制推送消息是否直接在前台显示
   completionHandler(UNNotificationPresentationOptionSound|UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionAlert);
}
```

3. 处理didReceiveNotificationResponse方法回调

```oc
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    NSDictionary * userInfo = response.notification.request.content.userInfo;
		//应用后台或者关闭时收到消息，回调flutter层onNotificationOpen方法
    [UmengPushSdkPlugin didOpenUMessage:userInfo];

    if ([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //应用处于后台时的远程推送接收
        //必须加这句代码
        [UMessage didReceiveRemoteNotification:userInfo];
    } else {
        //应用处于后台时的本地推送接收
    }
}
```

## 使用
```dart
import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:umeng_push_sdk/umeng_push_sdk.dart';
```

具体使用请下载[sdk](https://pub.dev/packages/umeng_push_sdk/versions)，参考sdk中的example工程。