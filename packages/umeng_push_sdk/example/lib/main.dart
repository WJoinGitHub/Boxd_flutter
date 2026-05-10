import 'package:flutter/material.dart';

import 'package:umeng_common_sdk/umeng_common_sdk.dart';
import 'package:umeng_push_sdk/umeng_push_sdk.dart';

import 'helper.dart';

void main() => runApp(MyApp());

const _TAG = "PushSample";

class _PushState extends State<Push> with AutomaticKeepAliveClientMixin {
  TextEditingController controller = TextEditingController();

  late Map<String, VoidCallback?> methods;

  int badgeNumber = 0;

  void registerPush() {
    UmengPushSdk.setLogEnable(true);
    UmengCommonSdk.initCommon(
        "5b960fb5a40fa3332e000082",
        "5f69a20ba246501b677d0923",
        "AppStore",
        "de1a9295ad7c8a23d3adcf5daac38c3f");
    UmengPushSdk.register("5f69a20ba246501b677d0923", "AppStore");
  }

  @override
  void initState() {
    super.initState();
    methods = {
      //模拟同意隐私政策
      'agree': () async => UmengHelper.agree().then((value) => registerPush()),
      //注册
      'register': () async => registerPush(),
      //获取DeviceToken
      'getDeviceToken': () async {
        String? deviceToken = await UmengPushSdk.getRegisteredId();
        if (deviceToken != null) {
          controller.text += deviceToken + "\n";
        }
      },
      //添加别名
      'addAlias': () async => controller.text +=
          (await UmengPushSdk.addAlias("myAlias", "SINA_WEIBO")).toString() +
              "\n",
      //移除别名
      'removeAlias': () async => controller.text +=
          (await UmengPushSdk.removeAlias("myAlias", "SINA_WEIBO")).toString() +
              "\n",
      //绑定别名
      'setAlias': () async => controller.text =
          (await UmengPushSdk.setAlias("myAlias", "SINA_WEIBO")).toString(),
      //添加标签
      'addTags': () async => controller.text +=
          (await UmengPushSdk.addTags(["myTag1", "myTag2", "myTag3"]))
                  .toString() +
              "\n",
      //移除标签
      'removeTags': () async => controller.text +=
          (await UmengPushSdk.removeTags(["myTag1", "myTag2", "myTag3"]))
                  .toString() +
              "\n",
      //获取已设置的标签
      'getAllTags': () async =>
          controller.text += (await UmengPushSdk.getTags()).toString() + "\n",
      //打开推送功能
      'openPush': () async => UmengPushSdk.setPushEnable(true),
      //关闭推送功能
      'closePush': () async => UmengPushSdk.setPushEnable(false),
      //清空日志
      'clear': () {
        controller.text = "";
      },
    };

    //设置deviceToken回调
    UmengPushSdk.setTokenCallback((deviceToken) {
      print("$_TAG deviceToken:" + deviceToken);
      controller.text += deviceToken + "\n";
    });

    //设置自定义消息回调
    UmengPushSdk.setMessageCallback((msg) {
      print("$_TAG receive custom:" + msg);
      controller.text += msg + "\n";
    });

    //设置通知消息回调
    UmengPushSdk.setNotificationCallback((receive) {
      print("$_TAG receive:" + receive);
      controller.text += "receive:" + receive + "\n";
    }, (open) {
      print("$_TAG open:" + open);
      controller.text += "open:" + open + "\n";
    });

    UmengHelper.isAgreed().then((value) => {
          if (value!) {registerPush()}
        });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
        appBar: AppBar(
          title: Text('PushSample'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              TextField(
                maxLines: 5,
                controller: controller,
              ),
              Expanded(
                  child: Wrap(
                runSpacing: 10,
                spacing: 10,
                children: methods.keys
                    .map((e) => ElevatedButton(
                          child: Text(e),
                          onPressed: methods[e],
                        ))
                    .toList(),
              )),
            ],
          ),
        ));
  }

  @override
  bool get wantKeepAlive => true;
}

class Push extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _PushState();
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _pageController = PageController();

  final _bodyList = [
    Push(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: PageView(
          controller: _pageController,
          children: _bodyList,
          onPageChanged: pageControllerTap,
          physics: NeverScrollableScrollPhysics(),
        ),
      ),
    );
  }

  void pageControllerTap(int index) {
    setState(() {});
  }

  void onTap(int index) {
    _pageController.jumpToPage(index);
  }
}
