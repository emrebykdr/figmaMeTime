import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/state_dots.dart';
import 'package:figmaap/widgets/app_card.dart';
import 'package:figmaap/widgets/page_sheet.dart';
import 'package:figmaap/widgets/error_retry.dart';
import 'package:figmaap/pages/professionals_calendar.dart';
import 'package:figmaap/pages/proffessionals_no_preference.dart';
import 'package:figmaap/services/professional_service.dart';
import 'package:figmaap/services/salon_service.dart';
import 'package:figmaap/pages/account_settings_page.dart';

class OnboardingChooseProfessional extends StatefulWidget {
  final bool isLoggedIn;
  final String selectedService;
  final String selectedPrice;

  const OnboardingChooseProfessional({
    super.key,
    this.isLoggedIn = false,
    this.selectedService = 'Basic Manicure',
    this.selectedPrice = '\$30',
  });

  @override
  State<OnboardingChooseProfessional> createState() =>
      _OnboardingChooseProfessionalState();
}

class _OnboardingChooseProfessionalState
    extends State<OnboardingChooseProfessional> {
  int? _selectedIndex;
  List<Map<String, dynamic>> _professionals = [];
  bool _loading = true;
  String? _error;
  bool _noSalonSelected = false;

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    setState(() {
      _loading = true;
      _error = null;
      _noSalonSelected = false;
    });
    final salonId = SalonService.currentSalonId;
    if (salonId == null) {
      setState(() {
        _noSalonSelected = true;
        _loading = false;
      });
      return;
    }
    try {
      final professionals = await ProfessionalService().getProfessionals(
        salonId: salonId,
      );
      if (!mounted) return;
      setState(() {
        _professionals = professionals;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load professionals.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: r.h(16)),
            _buildTopBar(context, r),
            SizedBox(height: r.h(52)),
            const StateDots(activeIndex: 2),
            SizedBox(height: r.h(38)),
            _buildTitle(r),
            SizedBox(height: r.h(32)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _noSalonSelected
                  ? _buildNoSalonView(r)
                  : _error != null
                  ? ErrorRetryView(
                      message: _error!,
                      onRetry: _loadProfessionals,
                    )
                  : _professionals.isEmpty
                  ? Center(
                      child: Text(
                        'No professionals available yet.',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w500,
                          fontSize: r.sp(14),
                          color: AppColors.tertiary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _professionals.length,
                      itemBuilder: (context, index) {
                        final pro = _professionals[index];
                        final rating =
                            (pro['rating'] as num?)?.toDouble() ?? 5.0;
                        return ProfessionalCard(
                          imagePath: pro['photoUrl'] as String? ?? '',
                          name: pro['name'] as String? ?? '',
                          role: pro['role'] as String? ?? '',
                          rating: rating,
                          isSelected: _selectedIndex == index,
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                            if (widget.isLoggedIn) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfessionalsCalendar(
                                    name: pro['name'] as String? ?? '',
                                    role: pro['role'] as String? ?? '',
                                    rating: rating,
                                    imagePath: pro['photoUrl'] as String? ?? '',
                                    selectedService: widget.selectedService,
                                    selectedPrice: widget.selectedPrice,
                                    workingHours:
                                        pro['workingHours']
                                            as Map<String, dynamic>? ??
                                        {},
                                    daysOff:
                                        (pro['daysOff'] as List?)
                                            ?.cast<String>() ??
                                        [],
                                  ),
                                ),
                              );
                            } else {
                              LoginSheet.show(
                                context,
                                professional: pro,
                                selectedService: widget.selectedService,
                                selectedPrice: widget.selectedPrice,
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
            _buildNoPreference(r),
            SizedBox(height: r.h(40)),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSalonView(Responsive r) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: r.w(40)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please choose a branch in Account Settings first.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w500,
                fontSize: r.sp(14),
                color: AppColors.tertiary,
              ),
            ),
            SizedBox(height: r.h(16)),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AccountSettingsPage()),
                );
              },
              child: Text(
                'Go to Account Settings',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w600,
                  fontSize: r.sp(14),
                  color: AppColors.primary,
                ),
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

  Widget _buildTitle(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(53)),
      child: Text(
        'Choose a professional e\nsee the slots available',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w600,
          fontSize: r.sp(24),
          height: 1.36,
          letterSpacing: -0.48,
          color: AppColors.secondary,
        ),
      ),
    );
  }

  Widget _buildNoPreference(Responsive r) {
    return GestureDetector(
      onTap: () {
        if (widget.isLoggedIn) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoPreference(
                selectedService: widget.selectedService,
                selectedPrice: widget.selectedPrice,
              ),
            ),
          );
        } else {
          LoginSheet.show(context, noPreference: true);
        }
      },
      child: Text(
        "I don't have a preference",
        style: TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w700,
          fontSize: r.sp(18),
          height: 1.0,
          color: AppColors.primary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.primary,
        ),
      ),
    );
  }
}
