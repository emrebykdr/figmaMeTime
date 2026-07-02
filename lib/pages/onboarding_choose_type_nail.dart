import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/state_dots.dart';
import 'package:figmaap/widgets/app_card.dart';
import 'package:figmaap/pages/onboarding_choose_proffesionel.dart';
import 'package:figmaap/services/service_catalog_service.dart';

class OnboardingChooseTypeNail extends StatefulWidget {
  final bool isLoggedIn;
  // onboarding_choose_service.dart'taki kategori kartlarından geliyor
  // (Nail/Eyebrowns/Massage/Hair). Doğrudan çağrılan yerlerde (ör.
  // main_page.dart'taki "Book again") varsayılan olarak Nail kalır.
  final String category;

  const OnboardingChooseTypeNail({
    super.key,
    this.isLoggedIn = false,
    this.category = 'Nail',
  });

  @override
  State<OnboardingChooseTypeNail> createState() => _OnboardingChooseTypeNailState();
}

class _OnboardingChooseTypeNailState extends State<OnboardingChooseTypeNail> {
  List<Map<String, dynamic>> _services = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final services = await ServiceCatalogService().getServices(category: widget.category);
    if (!mounted) return;
    setState(() {
      _services = services;
      _loading = false;
    });
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
            const StateDots(activeIndex: 1),
            SizedBox(height: r.h(38)),
            _buildTitle(r),
            SizedBox(height: r.h(32)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _services.isEmpty
                      ? Center(
                          child: Text(
                            'No services available yet.',
                            style: TextStyle(
                              fontFamily: 'Raleway',
                              fontWeight: FontWeight.w500,
                              fontSize: r.sp(14),
                              color: AppColors.tertiary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            final title = service['name'] as String? ?? '';
                            final price = service['price'] as String? ?? '';
                            return ServiceCard(
                              imagePath: service['photoUrl'] as String? ?? '',
                              title: title,
                              price: price,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OnboardingChooseProfessional(
                                      isLoggedIn: widget.isLoggedIn,
                                      selectedService: title,
                                      selectedPrice: price,
                                    ),
                                  ),
                                );
                              },
                            );
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

  Widget _buildTitle(Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(71)),
      child: Text(
        'Now, choose one\nthat fit your needs:',
        textAlign: TextAlign.center,
        style: TextStyle(fontFamily: 'Raleway',
          fontWeight: FontWeight.w600,
          fontSize: r.sp(24),
          height: 1.36,
          letterSpacing: -0.48,
          color: AppColors.secondary,
        ),
      ),
    );
  }
}
