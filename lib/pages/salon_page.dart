import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/error_retry.dart';
import 'package:figmaap/services/salon_service.dart';

class SalonPage extends StatefulWidget {
  final String salonId;

  const SalonPage({super.key, required this.salonId});

  @override
  State<SalonPage> createState() => _SalonPageState();
}

class _SalonPageState extends State<SalonPage> {
  Map<String, dynamic>? _salon;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSalon();
  }

  Future<void> _loadSalon() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final salon = await SalonService().getSalonById(widget.salonId);
      if (!mounted) return;
      setState(() {
        _salon = salon;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load salon.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: ErrorRetryView(message: _error!, onRetry: _loadSalon),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(context, r),
            SizedBox(height: r.h(24)),
            _buildActionButtons(r),
            SizedBox(height: r.h(16)),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            SizedBox(height: r.h(16)),
            _buildCoupons(r),
            SizedBox(height: r.h(16)),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            SizedBox(height: r.h(24)),
            _buildCustomerReviews(r),
            SizedBox(height: r.h(32)),
            _buildWriteReviewButton(r),
            SizedBox(height: r.h(40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroImage(BuildContext context, Responsive r) {
    final photoUrl = _salon?['photoUrl'] as String? ?? '';
    final name = _salon?['name'] as String? ?? 'The Gallery Salon';
    final address = _salon?['address'] as String? ?? '';
    final priceTier = _salon?['priceTier'] as String? ?? '';
    final subtitle = [address, priceTier].where((s) => s.isNotEmpty).join('  •  ');

    return SizedBox(
      width: double.infinity,
      height: r.h(380),
      child: Stack(
        children: [
          Positioned.fill(
            child: photoUrl.isEmpty
                ? Image.asset('assets/images/salon.jpg', fit: BoxFit.cover)
                : Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Image.asset('assets/images/salon.jpg', fit: BoxFit.cover),
                  ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(26)),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: SvgPicture.asset(
                      'assets/icons/light.svg',
                      width: r.w(24),
                      height: r.w(24),
                    ),
                  ),
                  const Spacer(),
                  const AppHeader(),
                  const Spacer(),
                  SizedBox(width: r.w(24)),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: r.h(50),
            left: r.w(30),
            child: Text(
              name,
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                fontSize: r.sp(32),
                color: AppColors.white,
              ),
            ),
          ),
          if (subtitle.isNotEmpty)
            Positioned(
              bottom: r.h(24),
              left: r.w(30),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w500,
                  fontSize: r.sp(14),
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionItemImage(r, 'assets/icons/phone.png', 'Call'),
          _buildActionItemImage(r, 'assets/icons/message.png', 'Message'),
          _buildActionItemImage(r, 'assets/icons/directions.png', 'Directions'),
          _buildActionItemImage(r, 'assets/icons/share.png', 'Share'),
        ],
      ),
    );
  }

  Widget _buildActionItemImage(Responsive r, String imagePath, String label) {
    return Column(
      children: [
        Container(
          width: r.w(56),
          height: r.w(56),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(r.r(12)),
          ),
          child: Center(
            child: Image.asset(imagePath, width: r.w(28), height: r.w(28)),
          ),
        ),
        SizedBox(height: r.h(8)),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(12),
            color: AppColors.almostBlack,
          ),
        ),
      ],
    );
  }

  Widget _buildCoupons(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: Row(
        children: [
          Expanded(child: _buildCouponCard(r, '10% off', 'use code FREE10')),
          SizedBox(width: r.w(12)),
          Expanded(child: _buildCouponCard(r, '30% off on Debit Card', 'No coupon required')),
        ],
      ),
    );
  }

  Widget _buildCouponCard(Responsive r, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: r.w(14), vertical: r.h(14)),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r.r(10)),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/Frame 21.svg',
                width: r.w(28),
                height: r.w(28),
              ),
              SizedBox(width: r.w(8)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w700,
                    fontSize: r.sp(14),
                    color: AppColors.almostBlack,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: r.h(4)),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(12),
              color: AppColors.tertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerReviews(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer reviews',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: r.sp(22),
              color: AppColors.almostBlack,
            ),
          ),
          SizedBox(height: r.h(8)),
          Text(
            '4.8 out of 5',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: r.sp(16),
              color: AppColors.almostBlack,
            ),
          ),
          SizedBox(height: r.h(4)),
          Text(
            '27 global ratings',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(14),
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: r.h(20)),
          _buildRatingBar(r, 5.0, 0.80),
          SizedBox(height: r.h(8)),
          _buildRatingBar(r, 4.5, 0.10),
          SizedBox(height: r.h(8)),
          _buildRatingBar(r, 3.0, 0.05),
          SizedBox(height: r.h(8)),
          _buildRatingBar(r, 2.0, 0.05),
          SizedBox(height: r.h(8)),
          _buildRatingBar(r, 1.0, 0.00),
        ],
      ),
    );
  }

  Widget _buildRatingBar(Responsive r, double starRating, double percentage) {
    return Row(
      children: [
        SizedBox(
          width: r.w(120),
          child: Row(
            children: List.generate(5, (index) {
              String svgPath;
              if (index < starRating.floor()) {
                svgPath = 'assets/icons/star_filled.svg';
              } else if (index < starRating) {
                svgPath = 'assets/icons/star_half.svg';
              } else {
                svgPath = 'assets/icons/star_empty.svg';
              }
              return SvgPicture.asset(
                svgPath,
                width: r.w(20),
                height: r.w(20),
              );
            }),
          ),
        ),
        SizedBox(width: r.w(12)),
        Text(
          '${(percentage * 100).toInt()}%',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(14),
            color: AppColors.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildWriteReviewButton(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(40)),
      child: SizedBox(
        width: double.infinity,
        height: r.h(54),
        child: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE0E0E0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.r(30)),
            ),
          ),
          child: Text(
            'Write a review',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w600,
              fontSize: r.sp(16),
              color: AppColors.almostBlack,
            ),
          ),
        ),
      ),
    );
  }
}
