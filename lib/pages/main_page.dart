import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/services/booking_service.dart';
import 'package:figmaap/pages/bookings_page.dart';
import 'package:figmaap/pages/onboarding_choose_type_nail.dart';
import 'package:figmaap/pages/salon_page.dart';
import 'package:figmaap/pages/home_page.dart';
import 'package:figmaap/pages/account_settings_page.dart';
import 'package:figmaap/pages/notifications_page.dart';
import 'package:figmaap/services/user_service.dart';
import 'package:figmaap/services/notification_service.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedCategory = 0;
  String _userName = 'Guest';
  String _searchQuery = '';
  final _searchController = TextEditingController();
  final _categories = ['Recommended', 'Packages', 'Professionals'];

  final _services = [
    {
      'image': 'assets/images/choose_hair.jpg',
      'name': 'Haircut',
      'duration': '45 mins',
      'price': '\$90',
    },
    {
      'image': 'assets/images/choose_massage.jpg',
      'name': 'Massage',
      'duration': '60 mins',
      'price': '\$60',
    },
    {
      'image': 'assets/images/choose_nail.jpg',
      'name': 'Manicure',
      'duration': '30 mins',
      'price': '\$30',
    },
    {
      'image': 'assets/images/choose_eyebrown.jpg',
      'name': 'Eyebrow',
      'duration': '20 mins',
      'price': '\$25',
    },
  ];

  StreamSubscription<bool>? _blockedSub;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _listenForAccountBlocked();
    NotificationService().checkTodayReminders();
  }

  // Admin panelden hesap engellendiğinde, uygulama açıkken bile anında
  // oturumu kapatıp giriş ekranına döner (main.dart'taki kontrol sadece
  // uygulama yeniden başladığında çalışıyor, bu ek olarak canlı dinliyor).
  void _listenForAccountBlocked() {
    _blockedSub = UserService().watchAccountBlocked().listen((blocked) async {
      if (!blocked) return;
      await UserService.logout();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    });
  }

  Future<void> _loadUserName() async {
    if (UserService.currentUserName != null && UserService.currentUserName!.isNotEmpty) {
      setState(() {
        _userName = UserService.currentUserName!;
      });
    } else if (UserService.currentUserId != null) {
      final user = await UserService().getUserById(UserService.currentUserId!);
      if (user != null && user['fullName'] != null && (user['fullName'] as String).isNotEmpty) {
        setState(() {
          _userName = user['fullName'];
        });
      }
    }
  }

  List<Map<String, String>> get _filteredServices {
    if (_searchQuery.isEmpty) return _services;
    return _services
        .where((s) => s['name']!.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _blockedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      drawer: _buildAppDrawer(r),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: r.h(16)),
              const Center(child: AppHeader()),
              SizedBox(height: r.h(16)),
              _buildTopMenu(r),
              SizedBox(height: r.h(16)),
              _buildSearchBar(r),
              SizedBox(height: r.h(20)),
              _buildAdsBanner(r),
              SizedBox(height: r.h(20)),
              _buildCategoryChips(r),
              SizedBox(height: r.h(20)),
              _buildUpcomingSection(r),
              SizedBox(height: r.h(24)),
              _buildServicesSection(r),
              SizedBox(height: r.h(30)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppDrawer(Responsive r) {
    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(r.w(24), r.h(24), r.w(24), r.h(16)),
              child: Text(
                _userName,
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700,
                  fontSize: r.sp(20),
                  color: AppColors.almostBlack,
                ),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            SizedBox(height: r.h(8)),
            _buildDrawerTile(
              r,
              icon: Icons.settings_outlined,
              label: 'Account Settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
                );
              },
            ),
            _buildNotificationsDrawerTile(r),
            const Spacer(),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            _buildDrawerTile(
              r,
              icon: Icons.logout,
              label: 'Log out',
              color: AppColors.cancel,
              onTap: () {
                Navigator.pop(context);
                _confirmLogout();
              },
            ),
            SizedBox(height: r.h(8)),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile(
    Responsive r, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.almostBlack),
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w600,
          fontSize: r.sp(15),
          color: color ?? AppColors.almostBlack,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildNotificationsDrawerTile(Responsive r) {
    return StreamBuilder<int>(
      stream: NotificationService().watchUnreadCount(),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return _buildDrawerTile(
          r,
          icon: Icons.notifications_none,
          label: 'Notifications',
          trailing: unread > 0
              ? Container(
                  padding: EdgeInsets.symmetric(horizontal: r.w(8), vertical: r.h(2)),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(r.r(12)),
                  ),
                  child: Text(
                    '$unread',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                      fontSize: r.sp(12),
                      color: AppColors.almostBlack,
                    ),
                  ),
                )
              : null,
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmLogout() async {
    final r = Responsive(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r.r(16))),
        title: Text(
          'Log out',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
            fontSize: r.sp(18),
            color: AppColors.almostBlack,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(14),
            color: AppColors.tertiary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w600,
                color: AppColors.tertiary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Log out',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                color: AppColors.cancel,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await UserService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
      (route) => false,
    );
  }

  Widget _buildTopMenu(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _scaffoldKey.currentState?.openDrawer(),
            child: SvgPicture.asset('assets/icons/menu.svg', width: r.w(25), height: r.w(25)),
          ),
          SizedBox(width: r.w(7)),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w500,
                fontSize: r.sp(24),
                height: 1.3,
                letterSpacing: -0.24,
                color: AppColors.almostBlack,
              ),
              children: [
                const TextSpan(text: 'Hello, '),
                TextSpan(
                  text: _userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: Container(
        width: r.w(314),
        height: r.h(54),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(r.r(10)),
        ),
        padding: EdgeInsets.symmetric(horizontal: r.w(16)),
        child: Row(
          children: [
            Image.asset(
              'assets/icons/search.png',
              width: r.w(24),
              height: r.w(24),
            ),
            SizedBox(width: r.w(8)),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w500,
                  fontSize: r.sp(14),
                  color: AppColors.almostBlack,
                ),
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w500,
                    fontSize: r.sp(14),
                    color: AppColors.tertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
                child: Icon(
                  Icons.close,
                  size: r.w(18),
                  color: AppColors.tertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdsBanner(Responsive r) {
    return SizedBox(
      height: r.h(140),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: r.w(30)),
        children: [
          _buildAdCard(r, 'Find the best\nhair stylist\nfor you.', 'assets/images/ads1.jpg'),
          SizedBox(width: r.w(12)),
          _buildAdCard(r, 'Relax with\nour massage\nspecials.', 'assets/images/ads2.png'),
          SizedBox(width: r.w(12)),
          _buildAdCard(r, 'Perfect nails\nfor every\noccasion.', 'assets/images/ads3.jpg'),
        ],
      ),
    );
  }

  Widget _buildAdCard(Responsive r, String text, String imagePath) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SalonPage()),
        );
      },
      child: Container(
      width: r.w(280),
      height: r.h(140),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.r(10)),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.4),
            BlendMode.darken,
          ),
        ),
      ),
      padding: EdgeInsets.all(r.w(16)),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
            fontSize: r.sp(20),
            height: 1.3,
            color: AppColors.white,
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildCategoryChips(Responsive r) {
    return SizedBox(
      height: r.h(32),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: r.w(18)),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isActive = _selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = index),
            child: Container(
              margin: EdgeInsets.only(right: r.w(8)),
              padding: EdgeInsets.symmetric(horizontal: r.w(16), vertical: r.h(4)),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary.withValues(alpha: 0.5) : Colors.transparent,
                borderRadius: BorderRadius.circular(r.r(10)),
                border: isActive
                    ? null
                    : Border.all(color: AppColors.tertiary, width: 0.5),
              ),
              child: Center(
                child: Text(
                  _categories[index],
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w600,
                    fontSize: r.sp(14),
                    height: 1.7,
                    color: isActive ? AppColors.almostBlack : AppColors.tertiary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpcomingSection(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: r.sp(18),
              height: 1.3,
              letterSpacing: -0.18,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: r.h(16)),
          StreamBuilder<QuerySnapshot>(
            stream: BookingService().getUpcomingBookings(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsPage(initialTab: 1))),
                  child: Container(
                    width: r.w(315),
                    height: r.h(72),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F9FB),
                      borderRadius: BorderRadius.circular(r.r(10)),
                    ),
                    child: Center(
                      child: Text(
                        'No upcoming bookings',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w500,
                          fontSize: r.sp(14),
                          color: AppColors.tertiary,
                        ),
                      ),
                    ),
                  ),
                );
              }
              final booking = snapshot.data!.docs.first.data() as Map<String, dynamic>;
              final date = booking['date'] as String? ?? '';
              final parts = date.split(', ');
              final dayNum = parts.length > 1 ? parts[1] : '';
              final dayName = parts.isNotEmpty ? parts[0] : '';

              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingsPage(initialTab: 1))),
                child: Container(
                  width: r.w(315),
                  height: r.h(72),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F9FB),
                    borderRadius: BorderRadius.circular(r.r(10)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: r.w(74),
                        height: r.h(72),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(r.r(10)),
                        ),
                        child: Center(
                          child: Text(
                            '$dayNum\n$dayName',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w700,
                              fontSize: r.sp(18),
                              height: 1.13,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: r.w(12)),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking['service'] as String? ?? '',
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w700,
                                fontSize: r.sp(14),
                                color: AppColors.almostBlack,
                              ),
                              ),
                            Text(
                              'with ${booking['professional'] as String? ?? ''}',
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w500,
                                fontSize: r.sp(12),
                                color: AppColors.tertiary,
                              ),
                            ),
                            Text(
                              '$dayName, ${booking['time'] as String? ?? ''}',
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w700,
                                fontSize: r.sp(14),
                                color: AppColors.almostBlack,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(right: r.w(16)),
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w600,
                            fontSize: r.sp(14),
                            color: AppColors.almostBlack,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Services',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: r.sp(18),
              height: 1.3,
              letterSpacing: -0.18,
              color: AppColors.secondary,
            ),
          ),
          SizedBox(height: r.h(16)),
          SizedBox(
            height: r.h(223),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filteredServices.length,
              itemBuilder: (context, index) {
                final service = _filteredServices[index];
                return _buildServiceCard(r, service);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(Responsive r, Map<String, String> service) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingChooseTypeNail(isLoggedIn: true)),
        );
      },
      child: Container(
        width: r.w(180),
        margin: EdgeInsets.only(right: r.w(12)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(r.r(10)),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(r.r(10))),
              child: Image.asset(
                service['image']!,
                width: r.w(180),
                height: r.h(120),
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(r.w(10)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['name']!,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                      fontSize: r.sp(16),
                      color: AppColors.almostBlack,
                    ),
                  ),
                  SizedBox(height: r.h(4)),
                  Row(
                    children: [
                      SvgPicture.asset('assets/icons/clock.svg', width: r.w(14), height: r.w(14)),
                      SizedBox(width: r.w(4)),
                      Text(
                        service['duration']!,
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w500,
                          fontSize: r.sp(12),
                          color: AppColors.tertiary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: r.h(4)),
                  Text(
                    service['price']!,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                      fontSize: r.sp(16),
                      color: AppColors.almostBlack,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
