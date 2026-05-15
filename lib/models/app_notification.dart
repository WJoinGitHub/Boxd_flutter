import 'dart:convert';

/// 通知实体：`GET /notifications` 列表项与 `GET /notifications/popup` 的 `data.popup` 共用字段
class AppNotification {
  final int id;
  final String? userId;
  final String title;
  final String content;
  final String contentType;
  final String? contentHtml;
  final String? type;
  final String? imageUrl;
  final String? actionLabel;
  final DateTime? createdAt;
  final DateTime? expireAt;
  final bool? isRead;
  final DateTime? readAt;
  final String? priority;

  const AppNotification({
    required this.id,
    this.userId,
    required this.title,
    required this.content,
    required this.contentType,
    this.contentHtml,
    this.type,
    this.imageUrl,
    this.actionLabel,
    this.createdAt,
    this.expireAt,
    this.isRead,
    this.readAt,
    this.priority,
  });

  /// 列表标题展示（空则占位）
  String get listTitle {
    final t = title.trim();
    return t.isEmpty ? '—' : t;
  }

  /// 是否按 HTML 渲染（含 `content_html` 带标签但缺省 `content_type` 的推断）
  bool get isHtml {
    if (contentType.toLowerCase() == 'html') return true;
    final h = contentHtml?.trim() ?? '';
    return h.isNotEmpty && h.contains('<');
  }

  /// 弹窗是否有可展示内容
  bool get hasDisplayableContent {
    if (isHtml && (contentHtml?.trim().isNotEmpty ?? false)) return true;
    return content.trim().isNotEmpty;
  }

  /// 弹窗左上角标题（空则 UI 不展示标题行）
  String? get popupTitle {
    final t = title.trim();
    return t.isEmpty ? null : t;
  }

  factory AppNotification.fromJson(
    Map<String, dynamic> m, {
    int? idOverride,
  }) {
    int id = idOverride ?? _parseId(m['id']);

    final content = (m['content'] ?? '').toString();
    var ct =
        (m['content_type'] ?? 'text').toString().trim().toLowerCase();
    // 与日志是否截断无关：jsonDecode 后整段 HTML 已在内存中完整保留
    final html = _asFullString(m['content_html']);
    final htmlTrim = html?.trim() ?? '';
    if (ct != 'html' &&
        htmlTrim.isNotEmpty &&
        htmlTrim.contains('<')) {
      ct = 'html';
    }

    String? actionLabel;
    final at = m['action_text']?.toString().trim();
    if (at != null && at.isNotEmpty) {
      actionLabel = at;
    } else {
      final bt = m['button_text']?.toString().trim();
      if (bt != null && bt.isNotEmpty) actionLabel = bt;
    }

    String? imageUrl = m['image_url']?.toString().trim();
    if (imageUrl != null && imageUrl.isEmpty) imageUrl = null;
    final dataRaw = m['data'];
    if (imageUrl == null && dataRaw != null) {
      imageUrl = _imageUrlFromDataField(dataRaw);
    }

    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return AppNotification(
      id: id,
      userId: m['user_id']?.toString(),
      title: (m['title'] ?? '').toString(),
      content: content,
      contentType: ct,
      contentHtml: html,
      type: m['type']?.toString(),
      imageUrl: imageUrl,
      actionLabel: actionLabel,
      createdAt: parseDt(m['created_at'] ?? m['createdAt']),
      expireAt: parseDt(m['expire_at'] ?? m['expireAt']),
      isRead: _parseBool(m['is_read'] ?? m['isRead']),
      readAt: parseDt(m['read_at'] ?? m['readAt']),
      priority: m['priority']?.toString(),
    );
  }

  /// 解析 `GET /notifications/popup` 完整响应；无有效弹窗时返回 `null`
  static AppNotification? fromPopupApiResponse(Map<String, dynamic> response) {
    if (response['code'] != 200) return null;
    final raw = response['data'];
    if (raw == null) return null;
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    if (m.isEmpty) return null;

    Map<String, dynamic> payload = m;
    final nested = m['popup'];
    if (nested is Map) {
      payload = Map<String, dynamic>.from(nested);
    }

    final item = AppNotification.fromJson(payload);
    if (!item.hasDisplayableContent) return null;
    return item;
  }

  static String? _asFullString(dynamic v) {
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  static int _parseId(dynamic rawId) {
    if (rawId is int) return rawId;
    if (rawId != null) return int.tryParse(rawId.toString()) ?? 0;
    return 0;
  }

  static bool? _parseBool(dynamic v) {
    if (v == null) return null;
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  static String? _imageUrlFromDataField(dynamic dataRaw) {
    try {
      Map<String, dynamic> map;
      if (dataRaw is String && dataRaw.trim().isNotEmpty) {
        final decoded = json.decode(dataRaw);
        if (decoded is! Map) return null;
        map = Map<String, dynamic>.from(decoded);
      } else if (dataRaw is Map) {
        map = Map<String, dynamic>.from(dataRaw);
      } else {
        return null;
      }
      for (final key in [
        'image_url',
        'imageUrl',
        'cover',
        'cover_url',
        'banner',
        'banner_url',
        'picture',
        'img',
      ]) {
        final v = map[key];
        if (v is String && v.trim().isNotEmpty) return v.trim();
      }
    } catch (_) {}
    return null;
  }
}
