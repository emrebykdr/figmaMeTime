import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/page_sheet.dart';

class BookingsPage extends StatefulWidget {
  final int initialTab;

  const BookingsPage({super.key, this.initialTab = 0});

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  late int _selectedTab;

  final _pastBookings = [
    {
      'salon': "Luna's Salon",
      'professional': 'Paty Sinclair',
      'distance': '5.0 Kms',
      'services': 'Basic Manicure 1 x',
      'date': '8 Mar 2022',
      'price': '\$30',
    },
    {
      'salon': 'The Gallery Salon',
      'professional': 'Anna Smith',
      'distance': '5.0 Kms',
      'services': 'Basic Manicure 1 x + Basic Pedicure 1 x',
      'date': '12 May 2022',
      'price': '\$65',
    },
    {
      'salon': 'The Gallery Salon',
      'professional': 'Anna Smith',
      'distance': '5.0 Kms',
      'services': 'Acrylic Extensions 1 x + Gel Manicure 1 x',
      'date': '8 Sep 2023',
      'price': '\$150',
    },
  ];

  final _upcomingBookings = [
    {
      'salon': 'The Gallery Salon',
      'professional': 'Anna Smith',
      'distance': '5.0 Kms',
      'services': 'Acrylic Extensions 1 x + Gel Manicure 1 x',
      'date': '19 Oct 2023',
      'price': '\$150',
    },
    {
      'salon': 'The Gallery Salon',
      'professional': 'Anna Smith',
      'distance': '5.0 Kms',
      'services': 'Gel Pedicure 1 x',
      'date': '31 Oct 2023',
      'price': '\$55',
    },
  ];

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
            SizedBox(height: r.h(32)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(30)),
              child: Text(
                'Your Bookings',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700,
                  fontSize: r.sp(28),
                  color: AppColors.almostBlack,
                ),
              ),
            ),
            SizedBox(height: r.h(24)),
            _buildTabs(r),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: r.w(30)),
                itemCount: _selectedTab == 0
                    ? _pastBookings.length
                    : _upcomingBookings.length,
                itemBuilder: (context, index) {
                  final booking = _selectedTab == 0
                      ? _pastBookings[index]
                      : _upcomingBookings[index];
                  return _buildBookingCard(r, booking, _selectedTab == 1);
                },
              ),
            ),
          ],
        ),
      ),
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
      child: Row(
        children: [
          _buildTab(r, 'Past', 0),
          SizedBox(width: r.w(24)),
          _buildTab(r, 'Upcoming', 1),
        ],
      ),
    );
  }

  Widget _buildTab(Responsive r, String label, int index) {
    final isActive = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w600,
              fontSize: r.sp(16),
              color: isActive ? AppColors.primary : AppColors.tertiary,
            ),
          ),
          SizedBox(height: r.h(8)),
          Container(
            height: 2,
            width: r.w(80),
            color: isActive ? AppColors.primary : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Responsive r, Map<String, String> booking, bool showCancel) {
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
            booking['salon']!,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: r.sp(16),
              color: AppColors.almostBlack,
            ),
          ),
          SizedBox(height: r.h(4)),
          Text(
            'with ${booking['professional']}  •  ${booking['distance']}',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(14),
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: r.h(4)),
          Text(
            booking['services']!,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(14),
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: r.h(4)),
          Text(
            '${booking['date']} • ${booking['price']}',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(14),
              color: AppColors.tertiary,
            ),
          ),
          if (showCancel) ...[
            SizedBox(height: r.h(8)),
            GestureDetector(
              onTap: () async {
                final confirmed = await CancelSheet.show(context);
                if (confirmed == true) {
                  setState(() {
                    _upcomingBookings.remove(booking);
                  });
                }
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w600,
                  fontSize: r.sp(14),
                  color: AppColors.cancel,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
