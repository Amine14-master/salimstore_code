import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_theme.dart';

class AdminNotification {
  AdminNotification({
    required this.title,
    required this.message,
    required this.timestamp,
    this.read = false,
  });

  final String title;
  final String message;
  final DateTime timestamp;
  bool read;
}

class AdminNotificationBell extends StatefulWidget {
  const AdminNotificationBell({
    super.key,
    this.initialNotifications,
    this.onNotificationsViewed,
    this.iconColor,
  });

  final List<AdminNotification>? initialNotifications;
  final VoidCallback? onNotificationsViewed;
  final Color? iconColor;

  @override
  State<AdminNotificationBell> createState() => _AdminNotificationBellState();
}

class _AdminNotificationBellState extends State<AdminNotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late List<AdminNotification> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = widget.initialNotifications != null
        ? widget.initialNotifications!
              .map(
                (n) => AdminNotification(
                  title: n.title,
                  message: n.message,
                  timestamp: n.timestamp,
                  read: n.read,
                ),
              )
              .toList()
        : _seededNotifications();

    _pulseController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1400),
          lowerBound: 0.96,
          upperBound: 1.07,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _pulseController.reverse();
          } else if (status == AnimationStatus.dismissed && _hasUnread) {
            _pulseController.forward();
          }
        });

    if (_hasUnread) {
      _pulseController.forward();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  bool get _hasUnread =>
      _notifications.any((notification) => notification.read == false);

  int get _unreadCount =>
      _notifications.where((notification) => notification.read == false).length;

  @override
  void didUpdateWidget(covariant AdminNotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialNotifications != oldWidget.initialNotifications) {
      setState(() {
        _notifications = widget.initialNotifications != null
            ? widget.initialNotifications!
                  .map(
                    (n) => AdminNotification(
                      title: n.title,
                      message: n.message,
                      timestamp: n.timestamp,
                      read: n.read,
                    ),
                  )
                  .toList()
            : _seededNotifications();
      });

      if (_hasUnread && !_pulseController.isAnimating) {
        _pulseController.forward();
      }
    }
  }

  List<AdminNotification> _seededNotifications() {
    final now = DateTime.now();
    return [
      AdminNotification(
        title: 'Nouvelle commande',
        message: 'Une nouvelle commande vient d\'être passée.',
        timestamp: now.subtract(const Duration(minutes: 12)),
      ),
      AdminNotification(
        title: 'Stock faible',
        message: 'Le stock de pommes Golden est inférieur à 10 unités.',
        timestamp: now.subtract(const Duration(hours: 3, minutes: 22)),
      ),
      AdminNotification(
        title: 'Promotion',
        message: 'Votre promotion "Pack Ramadan" se termine demain.',
        timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        read: true,
      ),
    ];
  }

  void _openNotifications() {
    if (!_hasUnread && _notifications.isEmpty) {
      _showBottomSheet();
      return;
    }

    _showBottomSheet();
    if (_hasUnread) {
      setState(() {
        for (final notification in _notifications) {
          notification.read = true;
        }
      });
      widget.onNotificationsViewed?.call();
      _pulseController.stop();
    }
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.9,
          minChildSize: 0.45,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.only(top: 18, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF4F6FF)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Centre de notifications',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_notifications.isEmpty)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Lottie.asset(
                            'lib/assets/animations/category_loader.json',
                            repeat: true,
                            height: 160,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Aucune notification pour le moment',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vous serez alerté dès qu\'une nouvelle activité est détectée.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.only(bottom: 24, top: 12),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          final timeAgo = _humanize(notification.timestamp);
                          final card = Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(
                                    0.08,
                                  ),
                                  blurRadius: 18,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: notification.read
                                    ? Colors.transparent
                                    : AppTheme.primaryColor.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor.withOpacity(0.18),
                                        AppTheme.secondaryColor.withOpacity(
                                          0.18,
                                        ),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active_rounded,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification.title,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                          ),
                                          Text(
                                            timeAgo,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        notification.message,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: AppTheme.textPrimary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (notification.read) {
                            return card;
                          }

                          return Shimmer.fromColors(
                            baseColor: AppTheme.primaryColor.withOpacity(0.25),
                            highlightColor: Colors.white,
                            period: const Duration(milliseconds: 1800),
                            child: card,
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _humanize(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    }
    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    }
    if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    }
    if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} j';
    }
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.iconColor ?? Colors.white;

    return ScaleTransition(
      scale: _pulseController,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _openNotifications,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor == Colors.white
                      ? Colors.white.withOpacity(0.1)
                      : AppTheme.primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: iconColor == Colors.white
                        ? Colors.white.withOpacity(0.2)
                        : Colors.transparent,
                  ),
                ),
                child: Icon(Icons.notifications_outlined, color: iconColor),
              ),
            ),
          ),
          if (_hasUnread)
            Positioned(
              top: -2,
              right: -2,
              child: Shimmer.fromColors(
                baseColor: AppTheme.errorColor,
                highlightColor: Colors.orangeAccent,
                period: const Duration(milliseconds: 1600),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    _unreadCount > 9 ? '9+' : _unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
