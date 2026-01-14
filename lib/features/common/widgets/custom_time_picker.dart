import 'package:flutter/material.dart';

class CustomTimePicker extends StatefulWidget {
  final TimeOfDay initialTime;
  final Function(TimeOfDay) onTimeChanged;

  const CustomTimePicker({
    super.key,
    required this.initialTime,
    required this.onTimeChanged,
  });

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late FixedExtentScrollController _periodController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  late int _selectedPeriod; // 0 for AM, 1 for PM
  late int _selectedHour; // 1-12
  late int _selectedMinute; // 0-59

  final List<String> _periods = ['上午', '下午'];
  final List<int> _hours = List<int>.generate(12, (index) => index + 1);
  final List<int> _minutes = List<int>.generate(60, (index) => index);

  @override
  void initState() {
    super.initState();
    _selectedPeriod = widget.initialTime.period == DayPeriod.am ? 0 : 1;
    _selectedHour = widget.initialTime.hourOfPeriod == 0 ? 12 : widget.initialTime.hourOfPeriod;
    _selectedMinute = widget.initialTime.minute;

    _periodController = FixedExtentScrollController(initialItem: _selectedPeriod);
    _hourController = FixedExtentScrollController(initialItem: _hours.indexOf(_selectedHour));
    _minuteController = FixedExtentScrollController(initialItem: _minutes.indexOf(_selectedMinute));
  }

  @override
  void dispose() {
    _periodController.dispose();
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  void _notifyTimeChanged() {
    int hourIn24;
    if (_selectedPeriod == 0) {
      // AM
      hourIn24 = _selectedHour == 12 ? 0 : _selectedHour;
    } else {
      // PM
      hourIn24 = _selectedHour == 12 ? 12 : _selectedHour + 12;
    }
    final newTime = TimeOfDay(hour: hourIn24, minute: _selectedMinute);
    widget.onTimeChanged(newTime);
  }

  @override
  Widget build(BuildContext context) {
    const unitStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 40),
        Expanded(
          flex: 1,
          child: _buildPicker(_periodController, _periods, (index) {
            setState(() {
              _selectedPeriod = index;
              _notifyTimeChanged();
            });
          }),
        ),
        Expanded(
          flex: 1,
          child: _buildPicker(_hourController, _hours, (index) {
            setState(() {
              _selectedHour = _hours[index];
              _notifyTimeChanged();
            });
          }),
        ),
        const Text('时', style: unitStyle),
        Expanded(
          flex: 1,
          child: _buildPicker(_minuteController, _minutes, (index) {
            setState(() {
              _selectedMinute = _minutes[index];
              _notifyTimeChanged();
            });
          }, padLeft: true),
        ),
        const Text('分', style: unitStyle),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildPicker(
    FixedExtentScrollController controller,
    List<dynamic> values,
    ValueChanged<int> onChanged, {
    bool padLeft = false,
  }) {
    return ListWheelScrollView(
      controller: controller,
      itemExtent: 40,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onChanged,
      children: values.map((value) {
        final text = padLeft && value is int ? value.toString().padLeft(2, '0') : value.toString();
        return Center(
          child: Text(
            text,
            style: const TextStyle(fontSize: 20, color: Colors.black),
          ),
        );
      }).toList(),
    );
  }
}
