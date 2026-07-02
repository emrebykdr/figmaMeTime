import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:figmaap/core(gerekli)/color.dart';
import 'package:figmaap/core(gerekli)/responsive.dart';
import 'package:figmaap/widgets/app_header.dart';
import 'package:figmaap/widgets/page_sheet.dart';
import 'package:figmaap/widgets/error_retry.dart';
import 'package:figmaap/pages/successful_page.dart';
import 'package:figmaap/services/booking_service.dart';
import 'package:figmaap/services/professional_service.dart';

class NoPreference extends StatefulWidget {
  final String selectedService;
  final String selectedPrice;

  const NoPreference({
    super.key,
    this.selectedService = 'Basic Manicure',
    this.selectedPrice = '\$30',
  });

  @override
  State<NoPreference> createState() => _NoPreferenceState();
}

class _NoPreferenceState extends State<NoPreference> {
  DateTime _selectedDate = DateTime.now();
  int _selectedDayIndex = 0;
  String? _selectedTime;
  Map<String, Set<String>> _bookedByProfessional = {};

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

  // Admin panelindeki (admin_web/uzmanlar.js) TIME_SLOTS/DAY_ORDER ile aynı.
  static const _timeSlots = [
    '10:00 am',
    '11:00 am',
    '01:30 pm',
    '03:00 pm',
    '05:00 pm',
    '07:00 pm',
  ];
  static const _dayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

  List<Map<String, dynamic>> _professionals = [];
  bool _loadingProfessionals = true;
  String? _error;
  // Seçili gün için, tüm uzmanların çalışma saatlerinden üretilen liste:
  // [{'time': '10:00 am', 'with': 'Anna Smith'}, ...]. Sabit liste değil.
  List<Map<String, String>> _availableSlots = [];

  String _dayKeyFor(DateTime date) => _dayKeys[date.weekday - 1];

  String _isoDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  List<DateTime> get _days {
    final now = DateTime.now();
    return List.generate(14, (i) => now.add(Duration(days: i)));
  }

  @override
  void initState() {
    super.initState();
    _loadProfessionals();
  }

  Future<void> _loadProfessionals() async {
    setState(() {
      _loadingProfessionals = true;
      _error = null;
    });
    try {
      final professionals = await ProfessionalService().getProfessionals();
      if (!mounted) return;
      setState(() {
        _professionals = professionals;
        _loadingProfessionals = false;
      });
      await _loadBookedSlots();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load available slots.';
        _loadingProfessionals = false;
      });
    }
  }

  Future<void> _loadBookedSlots() async {
    final dayName = _dayNames[_selectedDate.weekday % 7];
    final date = '$dayName, ${_selectedDate.day}';
    final dayKey = _dayKeyFor(_selectedDate);
    final isoDate = _isoDate(_selectedDate);

    // Seçili günde izinli olmayan, o gün çalışan uzmanlardan saat listesi üretilir.
    final slots = <Map<String, String>>[];
    for (final time in _timeSlots) {
      for (final professional in _professionals) {
        final daysOff =
            (professional['daysOff'] as List?)?.cast<String>() ?? [];
        if (daysOff.contains(isoDate)) continue;
        final workingHours =
            professional['workingHours'] as Map<String, dynamic>?;
        final dayTimes = (workingHours?[dayKey] as List?)?.cast<String>() ?? [];
        if (dayTimes.contains(time)) {
          slots.add({
            'time': time,
            'with': professional['name'] as String? ?? '',
          });
        }
      }
    }

    final professionalNames = slots.map((s) => s['with']!).toSet();
    try {
      final result = <String, Set<String>>{};
      for (final professional in professionalNames) {
        result[professional] = await BookingService().getBookedTimes(
          professional: professional,
          date: date,
        );
      }
      if (!mounted) return;
      setState(() {
        _availableSlots = slots;
        _bookedByProfessional = result;
        _error = null;
        if (_selectedTime != null) {
          final slot = _availableSlots.firstWhere(
            (s) => s['time'] == _selectedTime,
            orElse: () => {},
          );
          final withName = slot['with'];
          if (withName == null ||
              (_bookedByProfessional[withName]?.contains(_selectedTime) ??
                  false)) {
            _selectedTime = null;
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load available slots.';
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
            SizedBox(height: r.h(58)),
            _buildTitle(r),
            SizedBox(height: r.h(40)),
            const Divider(height: 1, color: Color(0xFFE0E0E0)),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: r.w(30)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: r.h(40)),
                    _buildMonthHeader(r),
                    SizedBox(height: r.h(24)),
                    _buildDayLabel(r),
                    SizedBox(height: r.h(24)),
                    _buildDaySelector(r),
                    SizedBox(height: r.h(32)),
                    _buildAvailabilityLabel(r),
                    SizedBox(height: r.h(20)),
                    _buildTimeGrid(r),
                    SizedBox(height: r.h(40)),
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
      padding: EdgeInsets.symmetric(horizontal: r.w(30)),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: TextStyle(
            fontFamily: 'Raleway',
            fontWeight: FontWeight.w700,
            fontSize: r.sp(24),
            height: 1.36,
            color: AppColors.almostBlack,
          ),
          children: const [
            TextSpan(text: 'Select a date to see the\n'),
            TextSpan(
              text: 'next ',
              style: TextStyle(color: AppColors.primary),
            ),
            TextSpan(text: 'slot available for you'),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthHeader(Responsive r) {
    return GestureDetector(
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
          _loadBookedSlots();
        }
      },
      child: Row(
        children: [
          Text(
            _monthNames[_selectedDate.month - 1],
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(18),
              color: AppColors.tertiary,
            ),
          ),
          SizedBox(width: r.w(6)),
          Text(
            '${_selectedDate.year}',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w500,
              fontSize: r.sp(18),
              color: AppColors.primary,
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
    );
  }

  Widget _buildDayLabel(Responsive r) {
    return Text(
      'Day',
      style: TextStyle(
        fontFamily: 'Raleway',
        fontWeight: FontWeight.w700,
        fontSize: r.sp(16),
        color: AppColors.almostBlack,
      ),
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
              _loadBookedSlots();
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

  Widget _buildAvailabilityLabel(Responsive r) {
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
    if (_loadingProfessionals) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorRetryView(message: _error!, onRetry: _loadProfessionals);
    }

    if (_availableSlots.isEmpty) {
      return Text(
        'No available slots for this day.',
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
      children: _availableSlots.map((slot) {
        final time = slot['time']!;
        final withName = slot['with']!;
        final isSelected = time == _selectedTime;
        final isBooked =
            _bookedByProfessional[withName]?.contains(time) ?? false;

        return GestureDetector(
          onTap: isBooked ? null : () => setState(() => _selectedTime = time),
          child: Container(
            width: r.w(150),
            padding: EdgeInsets.symmetric(vertical: r.h(10)),
            decoration: BoxDecoration(
              color: isBooked ? const Color(0xFFF0F0F0) : null,
              borderRadius: BorderRadius.circular(r.r(10)),
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xFFCDCDCD),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w500,
                    fontSize: r.sp(14),
                    color: isBooked
                        ? AppColors.tertiary
                        : (isSelected
                              ? AppColors.primary
                              : AppColors.almostBlack),
                  ),
                ),
                SizedBox(height: r.h(2)),
                Text(
                  'with $withName',
                  style: TextStyle(
                    fontFamily: 'Raleway',
                    fontWeight: FontWeight.w400,
                    fontSize: r.sp(12),
                    color: isBooked
                        ? AppColors.tertiary
                        : (isSelected ? AppColors.primary : AppColors.tertiary),
                  ),
                ),
              ],
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
                  final slot = _availableSlots.firstWhere(
                    (s) => s['time'] == _selectedTime,
                  );
                  try {
                    await BookingService().addBooking(
                      salon: 'The Gallery Salon',
                      professional: slot['with']!,
                      service: widget.selectedService,
                      date: '$dayName, ${_selectedDate.day}',
                      time: _selectedTime!,
                      price: widget.selectedPrice,
                      appointmentDate: _selectedDate,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          e.toString().replaceFirst('Exception: ', ''),
                        ),
                      ),
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
