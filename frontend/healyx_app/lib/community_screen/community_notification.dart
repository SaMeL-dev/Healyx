// 커뮤니티 알림창 화면
// GET   /api/notifications 알림 목록 조회
// PATCH /api/notifications/{notificationId}/read 알림 읽음 처리
import 'package:flutter/material.dart';

import '../app_language.dart';
import 'community_detail.dart';
import 'services/community_service.dart';

class CommunityNotificationScreen extends StatefulWidget {
  const CommunityNotificationScreen({super.key});

  @override
  State<CommunityNotificationScreen> createState() =>
      _CommunityNotificationScreenState();
}

class _CommunityNotificationScreenState
    extends State<CommunityNotificationScreen> {
  static const Color mainBlue = Color(0xFF2260FF);
  static const Color lightBlue = Color(0xFFE2EAFF);
  static const Color unreadBg = Color(0xFFF3F6FF);

  bool _isLoading = true;
  bool _isLoadingMore = false;

  String? _errorMessage;

  int _currentPage = 0;
  bool _isLastPage = true;

  final Set<int> _readingNotificationIds = {};
  List<CommunityNotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        setState(() {
          _currentPage = 0;
          _isLastPage = true;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      final result = await CommunityService().getNotifications(
        page: 0,
        size: 20,
      );

      if (!mounted) return;

      setState(() {
        _notifications = result.content;
        _currentPage = result.number;
        _isLastPage = result.last;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoadingMore || _isLastPage || _isLoading) return;

    try {
      setState(() {
        _isLoadingMore = true;
      });

      final nextPage = _currentPage + 1;

      final result = await CommunityService().getNotifications(
        page: nextPage,
        size: 20,
      );

      if (!mounted) return;

      setState(() {
        _notifications = [
          ..._notifications,
          ...result.content,
        ];
        _currentPage = result.number;
        _isLastPage = result.last;
      });
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  int _getTargetPostId(CommunityNotificationItem notification) {
    final type = _normalizeType(notification.type);

    if (notification.postId != null && notification.postId! > 0) {
      return notification.postId!;
    }

    if (type.contains('LIKE') && notification.referenceId > 0) {
      return notification.referenceId;
    }

    return 0;
  }

  Future<void> _handleNotificationTap(
      CommunityNotificationItem notification,
      ) async {
    if (_readingNotificationIds.contains(notification.notificationId)) {
      return;
    }

    try {
      setState(() {
        _readingNotificationIds.add(notification.notificationId);
      });

      if (!notification.read) {
        await CommunityService().markNotificationAsRead(
          notificationId: notification.notificationId,
        );

        if (!mounted) return;

        _replaceNotificationAsRead(notification.notificationId);
      }

      if (!mounted) return;

      final targetPostId = _getTargetPostId(notification);

      if (targetPostId <= 0) {
        _showSnackBar(AppLanguage.t('community_notification_no_post'));
        return;
      }

      await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => CommunityDetailScreen(
            postId: targetPostId,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() {
          _readingNotificationIds.remove(notification.notificationId);
        });
      }
    }
  }

  void _replaceNotificationAsRead(int notificationId) {
    setState(() {
      _notifications = _notifications.map((item) {
        if (item.notificationId != notificationId) {
          return item;
        }

        return CommunityNotificationItem(
          notificationId: item.notificationId,
          type: item.type,
          referenceId: item.referenceId,
          postId: item.postId,
          createdAt: item.createdAt,
          read: true,
        );
      }).toList();
    });
  }

  String _formatRelativeTime(String value) {
    final dateTime = DateTime.tryParse(value);

    if (dateTime == null) {
      return '';
    }

    final local = dateTime.toLocal();
    final now = DateTime.now();
    final difference = now.difference(local);

    if (difference.inSeconds < 60) {
      return AppLanguage.t('time_just_now');
    }

    if (difference.inMinutes < 60) {
      return AppLanguage.t('time_minutes_ago').replaceAll(
        '{count}',
        difference.inMinutes.toString(),
      );
    }

    if (difference.inHours < 24) {
      return AppLanguage.t('time_hours_ago').replaceAll(
        '{count}',
        difference.inHours.toString(),
      );
    }

    if (difference.inDays < 7) {
      return AppLanguage.t('time_days_ago').replaceAll(
        '{count}',
        difference.inDays.toString(),
      );
    }

    final year = local.year.toString();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');

    return '$year. $month. $day';
  }

  String _normalizeType(String type) {
    return type.trim().toUpperCase();
  }

  String _buildNotificationTitle(CommunityNotificationItem item) {
    final type = _normalizeType(item.type);

    if (type.contains('LIKE')) {
      return AppLanguage.t('notification_title_like');
    }

    if (type.contains('REPLY')) {
      return AppLanguage.t('notification_title_reply');
    }

    if (type.contains('COMMENT')) {
      return AppLanguage.t('notification_title_comment');
    }

    return AppLanguage.t('notification_title_default');
  }

  String _buildNotificationContent(CommunityNotificationItem item) {
    final type = _normalizeType(item.type);

    if (type.contains('LIKE')) {
      return AppLanguage.t('notification_content_like');
    }

    if (type.contains('REPLY')) {
      return AppLanguage.t('notification_content_reply');
    }

    if (type.contains('COMMENT')) {
      return AppLanguage.t('notification_content_comment');
    }

    return AppLanguage.t('notification_content_default');
  }

  IconData _getNotificationIcon(String type) {
    final normalizedType = _normalizeType(type);

    if (normalizedType.contains('LIKE')) {
      return Icons.favorite;
    }

    if (normalizedType.contains('REPLY')) {
      return Icons.forum_rounded;
    }

    if (normalizedType.contains('COMMENT')) {
      return Icons.chat_bubble_rounded;
    }

    return Icons.notifications_rounded;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 18),
        Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: mainBlue,
                    size: 22,
                  ),
                ),
              ),
            ),
            Text(
              AppLanguage.t('community_notification_title'),
              style: const TextStyle(
                color: mainBlue,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLoading() {
    return const Expanded(
      child: Center(
        child: CircularProgressIndicator(
          color: mainBlue,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: mainBlue,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ??
                    AppLanguage.t('community_notification_load_failed'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: ElevatedButton(
                  onPressed: _loadNotifications,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(21),
                    ),
                  ),
                  child: Text(
                    AppLanguage.t('retry'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Expanded(
      child: RefreshIndicator(
        color: mainBlue,
        onRefresh: () => _loadNotifications(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.58,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFFBBBBBB),
                      size: 58,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      AppLanguage.t('community_notification_empty'),
                      style: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return Expanded(
      child: RefreshIndicator(
        color: mainBlue,
        onRefresh: () => _loadNotifications(refresh: true),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.pixels >=
                notification.metrics.maxScrollExtent - 80) {
              _loadMoreNotifications();
            }

            return false;
          },
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _notifications.length + (_isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              if (index >= _notifications.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: mainBlue,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }

              final item = _notifications[index];
              final isProcessing =
              _readingNotificationIds.contains(item.notificationId);

              return _NotificationCard(
                icon: _getNotificationIcon(item.type),
                title: _buildNotificationTitle(item),
                content: _buildNotificationContent(item),
                time: _formatRelativeTime(item.createdAt),
                isRead: item.read,
                isProcessing: isProcessing,
                onTap: () => _handleNotificationTap(item),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;

    if (_isLoading) {
      body = _buildLoading();
    } else if (_errorMessage != null) {
      body = _buildError();
    } else if (_notifications.isEmpty) {
      body = _buildEmpty();
    } else {
      body = _buildNotificationList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            body,
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final String time;
  final bool isRead;
  final bool isProcessing;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.time,
    required this.isRead,
    required this.isProcessing,
    required this.onTap,
  });

  static const Color mainBlue = Color(0xFF2260FF);
  static const Color lightBlue = Color(0xFFE2EAFF);
  static const Color unreadBg = Color(0xFFF3F6FF);

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isRead ? 0.78 : 1,
      child: GestureDetector(
        onTap: isProcessing ? null : onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : unreadBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead ? Colors.transparent : lightBlue,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: lightBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: mainBlue,
                      size: 18,
                    ),
                  ),
                  if (!isRead)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: mainBlue,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      content,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Spacer(),
                        if (isProcessing)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              color: mainBlue,
                              strokeWidth: 2,
                            ),
                          )
                        else
                          Text(
                            time,
                            style: const TextStyle(
                              color: Colors.black38,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}