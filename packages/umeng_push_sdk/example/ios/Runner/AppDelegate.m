#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <UMCommonLog/UMCommonLogHeaders.h>
#import <UMCommon/UMConfigure.h>
#import <UserNotifications/UserNotifications.h>
#import <UMPush/UMessage.h>
#include <arpa/inet.h>

#if __has_include(<umeng_push_sdk/UmengPushSdkPlugin.h>)
#import <umeng_push_sdk/UmengPushSdkPlugin.h>
#else
@import umeng_push_sdk;
#endif

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
    [GeneratedPluginRegistrant registerWithRegistry:self];
    [UNUserNotificationCenter currentNotificationCenter].delegate=self;

    return [super application:application didFinishLaunchingWithOptions:launchOptions];
}



#pragma mark - UNUserNotificationCenterDelegate
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    
    NSDictionary * userInfo = notification.request.content.userInfo;
    [UmengPushSdkPlugin didReceiveUMessage:userInfo];
    NSLog(@"-----------willPresentNotification");

    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        [UMessage setAutoAlert:NO];
        //应用处于前台时的远程推送接受
        //必须加这句代码
        [UMessage didReceiveRemoteNotification:userInfo];
        
    }else{
        //应用处于前台时的本地推送接受
    }
    
    // 控制推送消息是否直接在前台显示
    completionHandler(UNNotificationPresentationOptionSound|UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionAlert);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void(^)(void))completionHandler {
    NSDictionary * userInfo = response.notification.request.content.userInfo;
    NSLog(@"-----------didReceiveNotificationResponse");
    [UmengPushSdkPlugin didOpenUMessage:userInfo];

    if([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //应用处于后台时的远程推送接受
        //必须加这句代码
        [UMessage didReceiveRemoteNotification:userInfo];
    }else{
        //应用处于后台时的本地推送接受
    }
}

@end
