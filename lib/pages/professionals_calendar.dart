import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/page_sheet.dart';
import 'package:figmaap/pages/successful_page.dart';
import 'package:figmaap/services/booking_service.dart';
import 'package:figmaap/services/salon_service.dart';


class ProfessionalsCalendar extends StatefulWidget {
  final String name;
  final String role;
  final double rating;
  final String imagePath;
  final String selectedService;
  final String selectedPrice;
  // Admin panelinde (admin_web/uzmanlar.html) tanımlanan haftalık müsaitlik:
  // {'mon': ['10:00 am', ...], 'tue': [...], ...}. Gün anahtarları Pazartesi=mon.
  final Map<String, dynamic> workingHours;
  // İzin/tatil günleri, ISO tarih string'i olarak ('2026-07-15').
  final List<String> daysOff;

  const ProfessionalsCalendar({
    super.key,
    required this.name,
    required this.role,
    required this.rating,
    required this.imagePath,
    this.selectedService = 'Basic Manicure',
    this.selectedPrice = '\$30',
    this.workingHours = const {},
    this.daysOff = const [],
  });

  @override
  State<ProfessionalsCalendar> createState() => _ProfessionalsCalendarState();
}

class _ProfessionalsCalendarState extends State<ProfessionalsCalendar> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  int _selectedDayIndex = 0;
  Set<String> _bookedTimes = {};

  final _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  final _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // Admin panelindeki (admin_web/uzmanlar.js) DAY_ORDER ile aynı sıra/anahtarlar.
  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  String _dayKeyFor(DateTime date) => _dayKeys[date.weekday - 1];

  String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Seçili günde uzmanın izinli olup olmadığına ve o gün için tanımlı
  /// çalışma saatlerine göre hesaplanan müsait saat listesi.
  List<String> get _availableTimes {
    if (widget.daysOff.contains(_isoDate(_selectedDate))) return [];
    final dayKey = _dayKeyFor(_selectedDate);
    final slots = widget.workingHours[dayKey];
    if (slots is List) return slots.cast<String>();
    return [];
  }

  List<DateTime> get _days {
    final now = DateTime.now();
    return List.generate(14, (i) => now.add(Duration(days: i)));
  }

  @override
  void initState() {
    super.initState();
    _loadBookedTimes();
  }

  Future<void> _loadBookedTimes() async {
    final dayName = _dayNames[_selectedDate.weekday % 7];
    final date = '$dayName, ${_selectedDate.day}';
    final times = await BookingService().getBookedTimes(
      salonId: SalonService.currentSalonId ?? '',
      professional: widget.name,
      date: date,
    );
    if (!mounted) return;
    setState(() {
      _bookedTimes = times;
      if (_selectedTime != null && _bookedTimes.contains(_selectedTime)) {
        _selectedTime = null;
      }
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
          child: widget.imagePath.isEmpty
              ? Container(
                  width: r.w(100),
                  height: r.w(100),
                  color: AppColors.cardBackground,
                  child: Icon(Icons.person, color: AppColors.white, size: r.w(50)),
                )
              : Image.network(
                  widget.imagePath,
                  width: r.w(100),
                  height: r.w(100),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: r.w(100),
                    height: r.w(100),
                    color: AppColors.cardBackground,
                    child: Icon(Icons.person, color: AppColors.white, size: r.w(50)),
                  ),
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
                _selectedDayIndex = picked
                    .difference(DateTime(now.year, now.month, now.day))
                    .inDays;
              });
              _loadBookedTimes();
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
              SvgPicture.asset(
                'assets/icons/chevron_right.svg',
                width: r.w(18),
                height: r.w(18),
              ),
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
              _loadBookedTimes();
            },
            child: Container(
              width: r.w(56),
              margin: EdgeInsets.only(right: r.w(8)),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(r.r(10)),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFFCDCDCD),
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
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.almostBlack,
                    ),
                  ),
                  Text(
                    dayName,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontWeight: FontWeight.w500,
                      fontSize: r.sp(12),
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.tertiary,
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
    if (_availableTimes.isEmpty) {
      return Text(
        'Not available on this day.',
        style: TextStyle(
          fontFamily: 'Raleway',
          fontWeight: FontWeight.w500,
          fontSize: r.sp(14),
          color: AppColors.tertiary,
        ),
      );
    }

    return Wrap(
      spacing: r.w(12),
      runSpacing: r.h(12),
      children: _availableTimes.map((time) {
        final isSelected = time == _selectedTime;
        final isBooked = _bookedTimes.contains(time);
        return GestureDetector(
          onTap: isBooked
              ? null
              : () {
                  setState(() {
                    _selectedTime = time;
                  });
                },
          child: Container(
            width: r.w(150),
            padding: EdgeInsets.symmetric(vertical: r.h(14)),
            decoration: BoxDecoration(
              color: isBooked ? const Color(0xFFF0F0F0) : null,
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
                  color: isBooked
                      ? AppColors.tertiary
                      : (isSelected ? AppColors.primary : AppColors.almostBlack),
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
              ? () async {
                  final dayName = _dayNames[_selectedDate.weekday % 7];
                  try {
                    await BookingService().addBooking(
                      salonId: SalonService.currentSalonId ?? '',
                      salon: SalonService.currentSalonName ?? '',
                      professional: widget.name,
                      service: widget.selectedService,
                      date: '$dayName, ${_selectedDate.day}',
                      time: _selectedTime!,
                      price: widget.selectedPrice,
                      appointmentDate: _selectedDate,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                    );
                    return;
                  }
                  if (!mounted) return;
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
