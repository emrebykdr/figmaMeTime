import 'package:flutter/material.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/pages/login_phone.dart';
import 'package:figmaap/pages/sign_up.dart';

// ─── Login Sheet ───

class LoginSheet extends StatelessWidget {
  final Map<String, dynamic>? professional;

  const LoginSheet({super.key, this.professional});

  static void show(BuildContext context, {Map<String, dynamic>? professional}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => LoginSheet(professional: professional),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(41), vertical: r.h(40)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hey there!',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              fontSize: r.sp(32),
              height: 1.3,
              letterSpacing: -0.32,
              color: AppColors.almostBlack,
            ),
          ),
          SizedBox(height: r.h(10)),
          Text(
            'Before schedule, please enter\nyour account or create one!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(18),
              height: 1.21,
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(height: r.h(37)),
          SizedBox(
            width: r.w(293),
            height: r.h(61),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LoginPhone(professional: professional)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.almostBlack,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(r.r(10)),
                ),
              ),
              child: Text(
                'Log In',
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w700,
                  fontSize: r.sp(16),
                  color: AppColors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: r.h(20)),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignUp()),
              );
            },
            child: Text(
              'Create Account',
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w700,
                fontSize: r.sp(16),
                height: 1.25,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(height: r.h(20)),
        ],
      ),
    );
  }
}

// ─── Cancel Appointment Sheet ───

class CancelSheet {
  static Future<bool?> show(BuildContext context) {
    final r = Responsive(context);
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) {
        return Center(
          child: Container(
            width: r.w(310),
            padding: EdgeInsets.symmetric(horizontal: r.w(24), vertical: r.h(32)),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(r.r(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/cancel.png',
                  width: r.w(66),
                  height: r.w(66),
                ),
                SizedBox(height: r.h(24)),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w600,
                      fontSize: r.sp(20),
                      height: 1.4,
                      color: AppColors.almostBlack,
                    ),
                    children: const [
                      TextSpan(text: 'Are you sure, you want to\n'),
                      TextSpan(
                        text: 'cancel',
                        style: TextStyle(color: AppColors.cancel),
                      ),
                      TextSpan(text: ' this appointment?'),
                    ],
                  ),
                ),
                SizedBox(height: r.h(32)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Text(
                        'No',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w600,
                          fontSize: r.sp(16),
                          color: AppColors.tertiary,
                        ),
                      ),
                    ),
                    SizedBox(width: r.w(32)),
                    SizedBox(
                      width: r.w(140),
                      height: r.h(48),
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.cancel,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(r.r(10)),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontWeight: FontWeight.w600,
                            fontSize: r.sp(16),
                            color: AppColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Day Picker Sheet ───

class DayPickerSheet {
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static Future<DateTime?> show(BuildContext context, DateTime current) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        DateTime selected = current;
        int viewMonth = current.month;
        int viewYear = current.year;

        return StatefulBuilder(
          builder: (context, setState) {
            final r = Responsive(context);
            final daysInMonth = DateTime(viewYear, viewMonth + 1, 0).day;
            final days = List.generate(
              daysInMonth,
              (i) => DateTime(viewYear, viewMonth, i + 1),
            );

            return Padding(
              padding: EdgeInsets.fromLTRB(r.w(16), r.h(24), r.w(16), r.h(24)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (viewMonth == 1) { viewMonth = 12; viewYear--; }
                            else { viewMonth--; }
                          });
                        },
                        child: Icon(Icons.chevron_left, size: r.w(24), color: AppColors.almostBlack),
                      ),
                      Text(
                        '${_monthNames[viewMonth - 1]} $viewYear',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w700,
                          fontSize: r.sp(18),
                          color: AppColors.almostBlack,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            if (viewMonth == 12) { viewMonth = 1; viewYear++; }
                            else { viewMonth++; }
                          });
                        },
                        child: Icon(Icons.chevron_right, size: r.w(24), color: AppColors.almostBlack),
                      ),
                    ],
                  ),
                  SizedBox(height: r.h(16)),
                  SizedBox(
                    height: r.h(80),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: days.length,
                      itemBuilder: (context, index) {
                        final day = days[index];
                        final isSelected = day.day == selected.day &&
                            day.month == selected.month &&
                            day.year == selected.year;
                        final dayName = _dayNames[day.weekday - 1];

                        return GestureDetector(
                          onTap: () => setState(() => selected = day),
                          child: Container(
                            width: r.w(56),
                            margin: EdgeInsets.only(right: r.w(8)),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(r.r(10)),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : const Color(0xFFCDCDCD),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontWeight: FontWeight.w600,
                                    fontSize: r.sp(18),
                                    color: isSelected ? AppColors.primary : AppColors.almostBlack,
                                  ),
                                ),
                                Text(
                                  dayName,
                                  style: TextStyle(
                                    fontFamily: 'Raleway',
                                    fontWeight: FontWeight.w500,
                                    fontSize: r.sp(12),
                                    color: isSelected ? AppColors.primary : AppColors.tertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: r.h(20)),
                  SizedBox(
                    width: r.w(200),
                    height: r.h(44),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, selected),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r.r(10)),
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w600,
                          fontSize: r.sp(14),
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Time Picker Sheet ───

class TimePickerSheet {
  static Future<String?> show(BuildContext context, List<String> times, String? selected) {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        String? current = selected;
        return StatefulBuilder(
          builder: (context, setState) {
            final r = Responsive(context);
            return Padding(
              padding: EdgeInsets.symmetric(vertical: r.h(24), horizontal: r.w(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select a time',
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w600,
                      fontSize: r.sp(18),
                      color: AppColors.almostBlack,
                    ),
                  ),
                  SizedBox(height: r.h(16)),
                  Wrap(
                    spacing: r.w(12),
                    runSpacing: r.h(12),
                    children: times.map((time) {
                      final isSelected = time == current;
                      return GestureDetector(
                        onTap: () => setState(() => current = time),
                        child: Container(
                          width: r.w(150),
                          padding: EdgeInsets.symmetric(vertical: r.h(12)),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(r.r(10)),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : const Color(0xFFCDCDCD),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              time,
                              style: TextStyle(
                                fontFamily: 'Raleway',
                                fontWeight: FontWeight.w500,
                                fontSize: r.sp(14),
                                color: isSelected ? AppColors.primary : AppColors.almostBlack,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: r.h(16)),
                  SizedBox(
                    width: r.w(200),
                    height: r.h(44),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, current),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(r.r(10)),
                        ),
                      ),
                      child: Text(
                        'Confirm',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontWeight: FontWeight.w600,
                          fontSize: r.sp(14),
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
