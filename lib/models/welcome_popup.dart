/// `GET /popups/welcome` 返回的欢迎弹窗内容
class WelcomePopup {
  final String title;
  final String content;
  final String buttonText;
  final bool showSnooze;
  final int snoozeDays;
  final String? email;

  const WelcomePopup({
    required this.title,
    required this.content,
    required this.buttonText,
    required this.showSnooze,
    required this.snoozeDays,
    this.email,
  });

  factory WelcomePopup.fromJson(Map<String, dynamic> m) {
    final days = m['snooze_days'];
    int snoozeDays = 15;
    if (days is int) {
      snoozeDays = days;
    } else if (days != null) {
      snoozeDays = int.tryParse(days.toString()) ?? 15;
    }
    String? email = m['email']?.toString().trim();
    if (email != null && email.isEmpty) email = null;

    return WelcomePopup(
      title: (m['title'] ?? '').toString(),
      content: (m['content'] ?? '').toString(),
      buttonText: (m['button_text'] ?? '').toString(),
      showSnooze: m['show_snooze'] == true,
      snoozeDays: snoozeDays,
      email: email,
    );
  }

  /// 解析完整响应；`should_show != true` 或无有效 popup 时返回 `null`
  static WelcomePopup? fromApiResponse(Map<String, dynamic> response) {
    if (response['code'] != 200) return null;
    final data = response['data'];
    if (data is! Map) return null;
    final m = Map<String, dynamic>.from(data);
    if (m['should_show'] != true) return null;
    final raw = m['popup'];
    if (raw is! Map) return null;
    final popup = WelcomePopup.fromJson(Map<String, dynamic>.from(raw));
    if (popup.title.trim().isEmpty && popup.content.trim().isEmpty) {
      return null;
    }
    return popup;
  }
}
