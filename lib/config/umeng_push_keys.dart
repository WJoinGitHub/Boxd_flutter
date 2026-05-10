/// 友盟推送相关密钥（集中管理，请勿提交到公开仓库时可改用 `--dart-define` 或 CI 注入）。
///
/// - [appKey]、[messageSecret]：客户端 SDK / Android manifest 占位符需要。
/// - [appMasterSecret]：**仅用于你们自己的服务端**调用友盟发推送 API 鉴权；
///   不要用在 App 网络请求里；Release 包可被反编译，**不要**把该常量传给任何客户端接口。
abstract final class UmengPushKeys {
  static const String appKey = '69ff635e6f259537c7a6a9f0';

  static const String messageSecret = '6e08714d2a10e280083b50174d9b851b';

  static const String appMasterSecret = 'rpcqxpntgha0mxlyympevxewjzcyfpfa';

  /// Android manifest / 统计渠道名，与 Gradle 中 [UmengPushKeys] 解析逻辑外的渠道保持一致。
  static const String channel = 'default';
}
