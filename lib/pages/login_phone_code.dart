import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/pages/professionals_calendar.dart';
import 'package:figmaap/pages/proffessionals_no_preference.dart';
import 'package:figmaap/pages/main_page.dart';
import 'package:figmaap/services/user_service.dart';

class LoginPhoneCode extends StatefulWidget {
  final String phoneNumber;
  final Map<String, dynamic>? professional;
  final bool noPreference;
  final bool isSignUp;
  final String selectedService;
  final String selectedPrice;

  const LoginPhoneCode({
    super.key,
    required this.phoneNumber,
    this.professional,
    this.noPreference = false,
    this.isSignUp = false,
    this.selectedService = 'Basic Manicure',
    this.selectedPrice = '\$30',
  });

  @override
  State<LoginPhoneCode> createState() => _LoginPhoneCodeState();
}

class _LoginPhoneCodeState extends State<LoginPhoneCode> {
  final List<TextEditingController> _controllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  late Timer _timer;
  int _remainingSeconds = 20;

  String? _expectedCode;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadExpectedCode();
  }

  // Admin panelinden (kullanici-detay.html -> "Kod Oluştur") üretilen kod,
  // users/{id}.loginCode alanında tutuluyor. Sabit '12345' yerine bu kontrol ediliyor.
  Future<void> _loadExpectedCode() async {
    final userData = await UserService().getUserByPhone(widget.phoneNumber);
    if (!mounted) return;
    setState(() {
      _expectedCode = userData?['loginCode'] as String?;
    });
  }

  void _startTimer() {
    _remainingSeconds = 20;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onCodeChanged(String value, int index) {
    if (value.length == 1 && index < 4) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    _checkCode();
  }

  void _checkCode() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 5) return;

    if (_expectedCode == null || code != _expectedCode) {
      setState(() {
        _errorText = 'Invalid code';
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    await UserService().loginUser(phone: widget.phoneNumber);
    if (!mounted) return;
    if (widget.isSignUp) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
        (route) => false,
      );
    } else if (widget.noPreference) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => NoPreference(
          selectedService: widget.selectedService,
          selectedPrice: widget.selectedPrice,
        )),
      );
    } else {
      final pro = widget.professional;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ProfessionalsCalendar(
            name: pro?['name'] as String? ?? 'Anna Smith',
            role: pro?['role'] as String? ?? 'Nail Designer',
            rating: (pro?['rating'] as num?)?.toDouble() ?? 5.0,
            imagePath: pro?['photoUrl'] as String? ?? '',
            selectedService: widget.selectedService,
            selectedPrice: widget.selectedPrice,
            workingHours: pro?['workingHours'] as Map<String, dynamic>? ?? {},
            daysOff: (pro?['daysOff'] as List?)?.cast<String>() ?? [],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: r.w(30)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: r.h(16)),
              _buildTopBar(context, r),
              SizedBox(height: r.h(74)),
              _buildTitle(r),
              SizedBox(height: r.h(10)),
              _buildSubtitle(r),
              SizedBox(height: r.h(32)),
              _buildCodeFields(r),
              if (_errorText != null) ...[
                SizedBox(height: r.h(8)),
                Text(
                  _errorText!,
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w500,
                    fontSize: r.sp(13),
                    color: AppColors.cancel,
                  ),
                ),
              ],
              const Spacer(),
              _buildResendRow(r),
              SizedBox(height: r.h(40)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, Responsive r) {
    return Stack(
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
    );
  }

  Widget _buildTitle(Responsive r) {
    return Text(
      'Enter code',
      style: TextStyle(
        fontFamily: 'Raleway',
        fontWeight: FontWeight.w700,
        fontSize: r.sp(32),
        height: 1.3,
        letterSpacing: -0.32,
        color: AppColors.almostBlack,
      ),
    );
  }

  Widget _buildSubtitle(Responsive r) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w500,
          fontSize: r.sp(16),
          height: 1.25,
          color: AppColors.tertiary,
        ),
        children: [
          const TextSpan(
            text: "We've sent an SMS with an activation code\nto your phone ",
          ),
          TextSpan(
            text: widget.phoneNumber,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppColors.almostBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeFields(Responsive r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        return Container(
          width: r.w(57),
          height: r.w(65),
          margin: EdgeInsets.only(right: index < 4 ? r.w(7) : 0),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            onChanged: (value) => _onCodeChanged(value, index),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: r.sp(24),
              color: AppColors.almostBlack,
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.symmetric(vertical: r.h(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(r.r(8)),
                borderSide: BorderSide(
                  color: AppColors.tertiary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(r.r(8)),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildResendRow(Responsive r) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _remainingSeconds == 0
                ? () {
                    _startTimer();
                    setState(() {});
                  }
                : null,
            child: Text(
              'Send code again',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w600,
                fontSize: r.sp(16),
                height: 1.25,
                color: AppColors.tertiary,
              ),
            ),
          ),
          SizedBox(width: r.w(12)),
          Text(
            _formattedTime,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w600,
              fontSize: r.sp(16),
              height: 1.25,
              color: AppColors.almostBlack,
            ),
          ),
        ],
      ),
    );
  }
}
