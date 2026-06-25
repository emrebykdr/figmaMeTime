import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/page_sheet.dart';
import 'package:figmaap/pages/successful_page.dart';

class ProfessionalsCalendar extends StatefulWidget {
  final String name;
  final String role;
  final double rating;
  final String imagePath;

  const ProfessionalsCalendar({
    super.key,
    required this.name,
    required this.role,
    required this.rating,
    required this.imagePath,
  });

  @override
  State<ProfessionalsCalendar> createState() => _ProfessionalsCalendarState();
}

class _ProfessionalsCalendarState extends State<ProfessionalsCalendar> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  int _selectedDayIndex = 0;

  final _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  final _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  final _availableTimes = [
    '10:00 am', '11:00 am', '01:30 pm',
    '03:00 pm', '07:00 pm', '05:00 pm',
  ];

  List<DateTime> get _days {
    final now = DateTime.now();
    return List.generate(14, (i) => now.add(Duration(days: i)));
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
            _buildBackButton(context, r),
            SizedBox(height: r.h(16)),
            _buildProfileSection(r),
            SizedBox(height: r.h(32)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: r.w(30)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(r, 'Select date & time'),
                    SizedBox(height: r.h(24)),
                    _buildDayHeader(r),
                    SizedBox(height: r.h(16)),
                    _buildDaySelector(r),
                    SizedBox(height: r.h(24)),
                    _buildAvailabilityTitle(r),
                    SizedBox(height: r.h(16)),
                    _buildTimeGrid(r),
                    SizedBox(height: r.h(32)),
                  ],
                ),
              ),
            ),
            _buildBookButton(r),
            SizedBox(height: r.h(24)),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, Responsive r) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: r.w(26)),
      child: Align(
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
    );
  }

  Widget _buildProfileSection(Responsive r) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(r.r(12)),
          child: Image.asset(
            widget.imagePath,
            width: r.w(100),
            height: r.w(100),
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: r.h(12)),
        Text(
          widget.name,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
            fontSize: r.sp(22),
            color: AppColors.almostBlack,
          ),
        ),
        SizedBox(height: r.h(4)),
        Text(
          widget.role,
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w500,
            fontSize: r.sp(14),
            color: AppColors.tertiary,
          ),
        ),
        SizedBox(height: r.h(6)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              'assets/icons/star.svg',
              width: r.w(18),
              height: r.w(18),
            ),
            SizedBox(width: r.w(4)),
            Text(
              widget.rating.toString(),
              style: TextStyle(
                fontFamily: 'Raleway',
                fontWeight: FontWeight.w600,
                fontSize: r.sp(14),
                color: AppColors.almostBlack,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(Responsive r, String title) {
    return Center(
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w700,
          fontSize: r.sp(22),
          color: AppColors.almostBlack,
        ),
      ),
    );
  }

  Widget _buildDayHeader(Responsive r) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Day',
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
            fontSize: r.sp(16),
            color: AppColors.almostBlack,
          ),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await DayPickerSheet.show(context, _selectedDate);
            if (picked != null) {
              setState(() {
                _selectedDate = picked;
                final now = DateTime.now();
                _selectedDayIndex = picked.difference(DateTime(now.year, now.month, now.day)).inDays;
              });
            }
          },
          child: Row(
            children: [
              Text(
                _monthNames[_selectedDate.month - 1],
                style: TextStyle(
                  fontFamily: 'Raleway',
                  fontWeight: FontWeight.w500,
                  fontSize: r.sp(14),
                  color: AppColors.almostBlack,
                ),
              ),
              SizedBox(width: r.w(4)),
              Icon(Icons.chevron_right, size: r.w(18), color: AppColors.almostBlack),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDaySelector(Responsive r) {
    final days = _days;
    return SizedBox(
      height: r.h(70),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = index == _selectedDayIndex;
          final dayName = _dayNames[day.weekday % 7];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDayIndex = index;
                _selectedDate = day;
              });
            },
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
    );
  }

  Widget _buildAvailabilityTitle(Responsive r) {
    return Text(
      'Availability',
      style: TextStyle(
        fontFamily: 'Raleway',
        fontWeight: FontWeight.w700,
        fontSize: r.sp(16),
        color: AppColors.almostBlack,
      ),
    );
  }

  Widget _buildTimeGrid(Responsive r) {
    return Wrap(
      spacing: r.w(12),
      runSpacing: r.h(12),
      children: _availableTimes.map((time) {
        final isSelected = time == _selectedTime;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTime = time;
            });
          },
          child: Container(
            width: r.w(150),
            padding: EdgeInsets.symmetric(vertical: r.h(14)),
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
    );
  }

  Widget _buildBookButton(Responsive r) {
    return Center(
      child: SizedBox(
        width: r.w(293),
        height: r.h(54),
        child: ElevatedButton(
          onPressed: _selectedTime != null
              ? () {
                  final dayName = _dayNames[_selectedDate.weekday % 7];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SuccessfulPage(
                        day: '$dayName, ${_selectedDate.day}',
                        time: _selectedTime!,
                      ),
                    ),
                  );
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(r.r(10)),
            ),
          ),
          child: Text(
            'Book',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w600,
              fontSize: r.sp(16),
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
