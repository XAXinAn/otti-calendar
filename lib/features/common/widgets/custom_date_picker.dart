import 'package:flutter/material.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateChanged;

  const CustomDatePicker({
    super.key,
    required this.initialDate,
    required this.onDateChanged,
  });

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;

  final List<int> _years = List<int>.generate(101, (index) => DateTime.now().year - 50 + index);
  final List<int> _months = List<int>.generate(12, (index) => index + 1);
  late List<int> _days;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
    _selectedDay = widget.initialDate.day;

    _days = _getDaysInMonth(_selectedYear, _selectedMonth);

    _yearController = FixedExtentScrollController(initialItem: _years.indexOf(_selectedYear));
    _monthController = FixedExtentScrollController(initialItem: _months.indexOf(_selectedMonth));
    _dayController = FixedExtentScrollController(initialItem: _days.indexOf(_selectedDay));
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  List<int> _getDaysInMonth(int year, int month) {
    return List<int>.generate(DateUtils.getDaysInMonth(year, month), (index) => index + 1);
  }

  void _updateDays() {
    final newDays = _getDaysInMonth(_selectedYear, _selectedMonth);
    if (_days.length != newDays.length) {
        setState(() {
            _days = newDays;
            if (_selectedDay > _days.length) {
                _selectedDay = _days.length;
                _dayController.animateToItem(
                    _selectedDay - 1, 
                    duration: const Duration(milliseconds: 300), 
                    curve: Curves.easeInOut,
                );
            }
        });
    }
    _notifyDateChanged();
  }

  void _notifyDateChanged() {
    final newDate = DateTime(_selectedYear, _selectedMonth, _selectedDay);
    widget.onDateChanged(newDate);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 40),
        Expanded(
          child: _buildPicker(_yearController, _years, (index) {
            setState(() {
              _selectedYear = _years[index];
              _updateDays();
            });
          }),
        ),
        const Text('年', style: TextStyle(fontSize: 20, color: Colors.black)),
        // const SizedBox(width: 10),
        Expanded(
          child: _buildPicker(_monthController, _months, (index) {
            setState(() {
              _selectedMonth = _months[index];
              _updateDays();
            });
          }),
        ),
        const Text('月', style: TextStyle(fontSize: 20, color: Colors.black)),
        // const SizedBox(width: 10),
        Expanded(
          child: _buildPicker(_dayController, _days, (index) {
            setState(() {
              _selectedDay = _days[index];
              _notifyDateChanged();
            });
          }),
        ),
        const Text('日', style: TextStyle(fontSize: 20, color: Colors.black)),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildPicker(
    FixedExtentScrollController controller,
    List<int> values,
    ValueChanged<int> onChanged,
  ) {
    return ListWheelScrollView(
      controller: controller,
      itemExtent: 40,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      perspective: 0.001,
      children: values.map((value) => Center(
        child: Text('$value', style: const TextStyle(fontSize: 20, color: Colors.black)),
      )).toList(),
    );
  }
}
