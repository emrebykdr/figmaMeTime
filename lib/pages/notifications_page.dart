import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Sayfa açılınca hepsi okunmuş sayılır; drawer'daki rozet buna göre kaybolur.
    _notificationService.markAllAsRead();
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'reminder':
        return Icons.access_time;
      default:
        return Icons.notifications_none;
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: r.h(16)),
            _buildTopBar(context, r),
            SizedBox(height: r.h(40)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(30)),
              child: Text(
                'Notifications',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w600,
                  fontSize: r.sp(24),
                  height: 1.36,
                  letterSpacing: -0.48,
                  color: AppColors.secondary,
                ),
              ),
            ),
            SizedBox(height: r.h(24)),
            Expanded(child: _buildList(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: SvgPicture.asset(
                'assets/icons/arrow_back.svg',
                width: r.w(24),
                height: r.w(24),
              ),
            ),
          ),
          const AppHeader(),
        ],
      ),
    );
  }

  Widget _buildList(Responsive r) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _notificationService.watchNotifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Something went wrong loading notifications.',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w500,
                fontSize: r.sp(14),
                color: AppColors.tertiary,
              ),
            ),
          );
        }

        final docs = [...snapshot.data?.docs ?? []];
        docs.sort((a, b) {
          final aTime = a.data()['createdAt'] as Timestamp?;
          final bTime = b.data()['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No notifications yet',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w500,
                fontSize: r.sp(16),
                color: AppColors.tertiary,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: r.w(30)),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data();
            final isRead = data['read'] == true;
            return Container(
              margin: EdgeInsets.only(bottom: r.h(12)),
              padding: EdgeInsets.all(r.w(14)),
              decoration: BoxDecoration(
                color: isRead ? AppColors.white : const Color(0xFFFFF6F4),
                borderRadius: BorderRadius.circular(r.r(10)),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _iconFor(data['type'] as String?),
                    color: AppColors.primary,
                    size: r.w(24),
                  ),
                  SizedBox(width: r.w(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['title'] as String? ?? '',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                            fontSize: r.sp(15),
                            color: AppColors.almostBlack,
                          ),
                        ),
                        SizedBox(height: r.h(4)),
                        Text(
                          data['body'] as String? ?? '',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w500,
                            fontSize: r.sp(13),
                            color: AppColors.tertiary,
                          ),
                        ),
                        SizedBox(height: r.h(6)),
                        Text(
                          _formatDate(data['createdAt'] as Timestamp?),
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w500,
                            fontSize: r.sp(11),
                            color: AppColors.tertiary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
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
}
