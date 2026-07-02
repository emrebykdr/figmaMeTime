import 'package:flutter/material.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';

/// Firestore'dan veri çekerken hata olursa (ağ kopması, izin hatası vb.)
/// ekranın sonsuza kadar yükleniyor durumunda kalmaması için gösterilen
/// basit hata + tekrar dene görünümü.
class ErrorRetryView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetryView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(14),
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: r.h(12)),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Try again',
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
    );
  }
}
