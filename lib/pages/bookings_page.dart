import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/page_sheet.dart';
import 'package:figmaap/services/booking_service.dart';

class BookingsPage extends StatefulWidget {
  final int initialTab;

  const BookingsPage({super.key, this.initialTab = 0});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  late int _selectedTab;
  final _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
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
            SizedBox(height: r.h(57)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(30)),
              child: Text(
                'Your Bookings',
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
            SizedBox(height: r.h(34)),
            _buildTabs(r),
            Expanded(
              child: _buildBookingList(r),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingList(Responsive r) {
    final stream = _selectedTab == 0
        ? _bookingService.getPastBookings()
        : _bookingService.getUpcomingBookings();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              _selectedTab == 0 ? 'No past bookings' : 'No upcoming bookings',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w500,
                fontSize: r.sp(16),
                color: AppColors.tertiary,
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: r.w(30)),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final docId = docs[index].id;
            return _buildBookingCard(r, data, docId, _selectedTab == 1);
          },
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(26)),
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

  Widget _buildTabs(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: SizedBox(
        width: r.w(314),
        height: r.h(48),
        child: Column(
          children: [
            Row(
              children: [
                _buildTab(r, 'Past', 0),
                _buildTab(r, 'Upcoming', 1),
              ],
            ),
            const Spacer(),
            Stack(
              children: [
                Container(
                  width: r.w(314),
                  height: 1,
                  color: const Color(0xFFE0E0E0),
                ),
                Row(
                  children: [
                    Container(
                      width: r.w(157),
                      height: 2,
                      color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                    ),
                    Container(
                      width: r.w(157),
                      height: 2,
                      color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(Responsive r, String label, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: SizedBox(
        width: r.w(157),
        height: r.h(24),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w600,
              fontSize: r.sp(16),
              height: 1.5,
              color: isActive ? AppColors.primary : AppColors.secondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(Responsive r, Map<String, dynamic> booking, String docId, bool showCancel) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: r.h(16)),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking['salon'] ?? '',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: r.sp(16),
              height: 1.4,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: r.h(4)),
          Text(
            'with ${booking['professional'] ?? ''}',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(16),
              height: 1.0,
              letterSpacing: 0.1,
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: r.h(4)),
          Text(
            booking['service'] ?? '',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(16),
              height: 1.0,
              letterSpacing: 0.1,
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: r.h(4)),
          Text(
            '${booking['date'] ?? ''} • ${booking['time'] ?? ''} • ${booking['price'] ?? ''}',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(16),
              height: 1.0,
              letterSpacing: 0.1,
              color: AppColors.tertiary,
            ),
          ),
          if (showCancel) ...[
            SizedBox(height: r.h(8)),
            GestureDetector(
              onTap: () async {
                final confirmed = await CancelSheet.show(context);
                if (confirmed == true) {
                  await _bookingService.cancelBooking(docId);
                }
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w600,
                  fontSize: r.sp(14),
                  color: AppColors.cancelText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
