import 'package:flutter/material.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/pages/bookings_page.dart';
import 'package:figmaap/pages/onboarding_choose_type_nail.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedCategory = 0;
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

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
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

  Widget _buildTopMenu(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: Row(
        children: [
          Icon(Icons.menu, size: r.w(25), color: AppColors.almostBlack),
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
              children: const [
                TextSpan(text: 'Hello, '),
                TextSpan(
                  text: 'Carol',
                  style: TextStyle(
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
            Text(
              'Search',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w500,
                fontSize: r.sp(14),
                height: 1.13,
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
    return Container(
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
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BookingsPage(initialTab: 1)),
              );
            },
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
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(r.r(10)),
                      border: Border.all(color: AppColors.primary, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '19\nOct',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w700,
                          fontSize: r.sp(18),
                          height: 1.13,
                          color: AppColors.primary,
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
                          'Basic Pedicure',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w700,
                            fontSize: r.sp(14),
                            color: AppColors.almostBlack,
                          ),
                        ),
                        Text(
                          'with Paty',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w500,
                            fontSize: r.sp(12),
                            color: AppColors.tertiary,
                          ),
                        ),
                        Text(
                          'Tuesday, 04:30pm',
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
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
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
                      Icon(Icons.access_time, size: r.w(14), color: AppColors.tertiary),
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
