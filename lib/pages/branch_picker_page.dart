import 'package:flutter/material.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/error_retry.dart';
import 'package:figmaap/services/salon_service.dart';
import 'package:figmaap/pages/onboarding_choose_service.dart';

/// Misafir (giriş yapmamış) kullanıcı randevu akışına girmeden önce hangi
/// şubede işlem yapacağını seçer. Giriş yapmış kullanıcının şube tercihi
/// Hesap Ayarları'ndan geldiği ve oturumlar arası kalıcı olduğu için,
/// misafir akışında bu ekran her zaman gösterilir — önceden (örn. başka bir
/// hesapla giriş yapılıp çıkış yapılmadan önce) seçilmiş bir şube varsa bile
/// atlanmaz; aksi halde bir önceki hesabın şubesi sessizce kullanılmış olur.
class BranchPickerPage extends StatefulWidget {
  const BranchPickerPage({super.key});

  @override
  State<BranchPickerPage> createState() => _BranchPickerPageState();
}

class _BranchPickerPageState extends State<BranchPickerPage> {
  List<Map<String, dynamic>> _salons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSalons();
  }

  Future<void> _loadSalons() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final salons = await SalonService().getSalons();
      if (!mounted) return;
      setState(() {
        _salons = salons;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load branches.';
        _loading = false;
      });
    }
  }

  Future<void> _selectSalon(Map<String, dynamic> salon) async {
    await SalonService.selectSalon(
      salon['id'] as String,
      salon['name'] as String? ?? '',
    );
    if (!mounted) return;
    _proceed();
  }

  void _proceed() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingChooseService()),
    );
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
            const AppHeader(),
            SizedBox(height: r.h(32)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: r.w(30)),
              child: Text(
                'Choose a branch',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700,
                  fontSize: r.sp(24),
                  color: AppColors.almostBlack,
                ),
              ),
            ),
            SizedBox(height: r.h(24)),
            Expanded(child: _buildBody(r)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(Responsive r) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ErrorRetryView(message: _error!, onRetry: _loadSalons);
    }
    if (_salons.isEmpty) {
      return Center(
        child: Text(
          'No branches available yet.',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(14),
            color: AppColors.tertiary,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      itemCount: _salons.length,
      itemBuilder: (context, index) => _buildSalonCard(r, _salons[index]),
    );
  }

  Widget _buildSalonCard(Responsive r, Map<String, dynamic> salon) {
    final name = salon['name'] as String? ?? '';
    final address = salon['address'] as String? ?? '';
    final photoUrl = salon['photoUrl'] as String? ?? '';

    return GestureDetector(
      onTap: () => _selectSalon(salon),
      child: Container(
        margin: EdgeInsets.only(bottom: r.h(12)),
        padding: EdgeInsets.all(r.w(12)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(r.r(10)),
          border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(r.r(8)),
              child: _buildSalonPhoto(r, photoUrl),
            ),
            SizedBox(width: r.w(14)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w700,
                      fontSize: r.sp(16),
                      color: AppColors.almostBlack,
                    ),
                  ),
                  if (address.isNotEmpty) ...[
                    SizedBox(height: r.h(4)),
                    Text(
                      address,
                      style: TextStyle(
                        fontFamily: 'Raleway',
                        fontWeight: FontWeight.w500,
                        fontSize: r.sp(13),
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // admin_web/salonlar.html'den girilen fotoğraf URL'si (varsa) ağ üzerinden
  // yükleniyor; boşsa/yüklenemezse yer tutucu ikon gösterilir (bkz.
  // widgets/app_card.dart -> _ProfessionalPhoto ile aynı desen).
  Widget _buildSalonPhoto(Responsive r, String photoUrl) {
    final size = r.w(64);
    if (photoUrl.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: AppColors.cardBackground,
        child: Icon(Icons.storefront, color: AppColors.white, size: size * 0.5),
      );
    }
    return Image.network(
      photoUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: AppColors.cardBackground,
        child: Icon(Icons.storefront, color: AppColors.white, size: size * 0.5),
      ),
    );
  }
}
