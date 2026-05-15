import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_boxd_app_flow/gen/assets.gen.dart';
import 'package:flutter_boxd_app_flow/l10n/app_localizations.dart';
import 'package:flutter_boxd_app_flow/models/app_notification.dart';
import 'package:flutter_boxd_app_flow/services/api_client.dart';
import 'package:flutter_boxd_app_flow/services/user_service.dart';
import 'package:flutter_boxd_app_flow/utils/app_colors.dart';
import 'package:flutter_boxd_app_flow/utils/app_toast.dart';
import 'package:flutter_boxd_app_flow/utils/dialog_button_styles.dart';
import 'package:flutter_boxd_app_flow/widgets/home_notification_popup.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

/// 通知列表：GET `/notifications`；首次成功展示后 PUT `/notifications/read-all`；左滑删除需确认后 DELETE
class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  List<AppNotification> _items = [];
  bool _loading = true;
  String? _errorKey;
  bool _readAllRequestedAfterFirstList = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _errorKey = null;
    });
    try {
      final result = await ApiClient.getNotifications(page: 1, pageSize: 100);
      if (!mounted) return;
      if (result['code'] == 200) {
        setState(() {
          _items = _parseItems(result);
          _loading = false;
        });
        if (!_readAllRequestedAfterFirstList) {
          _readAllRequestedAfterFirstList = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              unawaited(_markAllNotificationsRead());
            }
          });
        }
      } else {
        setState(() {
          _items = [];
          _loading = false;
          _errorKey = 'messages_load_failed';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _loading = false;
        _errorKey = 'messages_load_failed';
      });
    }
  }

  Future<void> _markAllNotificationsRead() async {
    if (!UserService().isLoggedIn || UserService().isGuestMode) return;
    try {
      await ApiClient.markAllNotificationsRead();
    } catch (_) {
      // 静默失败：不影响列表展示
    }
  }

  List<AppNotification> _parseItems(Map<String, dynamic> result) {
    final data = result['data'];
    List<dynamic> list = [];
    if (data is Map) {
      final n = data['notifications'];
      if (n is List) {
        list = n;
      } else {
        final inner = data['items'] ??
            data['list'] ??
            data['records'] ??
            data['data'];
        if (inner is List) list = inner;
      }
    } else if (data is List) {
      list = data;
    }
    final out = <AppNotification>[];
    var fallbackId = 1;
    for (final e in list) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      int id = 0;
      final rawId = m['id'];
      if (rawId is int) {
        id = rawId;
      } else if (rawId != null) {
        id = int.tryParse(rawId.toString()) ?? 0;
      }
      if (id == 0) id = fallbackId++;
      out.add(AppNotification.fromJson(m, idOverride: id));
    }
    return out;
  }

  String _formatTime(BuildContext context, DateTime? t, AppLocalizations l10n) {
    if (t == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(t.year, t.month, t.day);
    final diffDays = today.difference(d).inDays;
    final diff = now.difference(t);

    if (diff.inMinutes < 1) return l10n.t('time_just_now');
    if (diff.inHours < 1) {
      return l10n
          .t('time_minutes_ago')
          .replaceAll('{minutes}', '${diff.inMinutes}');
    }
    if (diffDays == 0 && diff.inHours < 24) {
      return l10n
          .t('time_hours_ago')
          .replaceAll('{hours}', '${diff.inHours.clamp(1, 23)}');
    }
    if (diffDays == 1) return l10n.t('time_yesterday');
    final locale = Localizations.localeOf(context).toString();
    return DateFormat('yyyy.MM.dd HH:mm', locale).format(t);
  }

  Future<void> _onDeletePressed(AppNotification item) async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.t('delete')),
        content: Text(l10n.t('notification_delete_confirm')),
        actions: [
          TextButton(
            style: DialogButtonStyles.cancel,
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.t('cancel')),
          ),
          TextButton(
            style: DialogButtonStyles.primaryAction,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.t('confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final r = await ApiClient.deleteNotification(item.id);
      if (!mounted) return;
      if (r['code'] == 200) {
        setState(() {
          _items.removeWhere((e) => e.id == item.id);
        });
      } else {
        AppToast.show(context, l10n.t('notification_delete_failed'));
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, ApiClient.extractErrorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      appBar: AppBar(
        backgroundColor: AppColors.pageBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, color: AppColors.black1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: Text(
          l10n.t('notifications_title'),
          style: TextStyle(
            color: AppColors.black1,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorKey != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.t(_errorKey!),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.gray3),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: _items.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.3,
                            ),
                            Center(
                              child: Text(
                                l10n.t('messages_empty'),
                                style: TextStyle(
                                  color: AppColors.gray3,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(13, 0, 13, 24),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final timeLabel =
                                _formatTime(context, item.createdAt, l10n);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Slidable(
                                key: ValueKey('slidable_${item.id}'),
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  extentRatio: 0.22,
                                  children: [
                                    SlidableAction(
                                      onPressed: (_) => _onDeletePressed(item),
                                      backgroundColor: Colors.red.shade600,
                                      foregroundColor: Colors.white,
                                      icon: Icons.delete_outline,
                                      label: l10n.t('delete'),
                                    ),
                                  ],
                                ),
                                child: _MessageCard(
                                  item: item,
                                  timeLabel: timeLabel,
                                ),
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final AppNotification item;
  final String timeLabel;

  const _MessageCard({
    required this.item,
    required this.timeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: () => HomeNotificationPopup.show(context, item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Assets.home.images.iconMessage.image(
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.listTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black1,
                      ),
                    ),
                  ),
                  if (timeLabel.isNotEmpty)
                    Text(
                      timeLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray4,
                      ),
                    ),
                ],
              ),
              if (item.content.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Text(
                    item.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: AppColors.gray3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
