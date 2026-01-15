import 'package:flutter/material.dart';

class CustomGenderPicker extends StatefulWidget {
  final String initialGender;
  final Function(String) onGenderChanged;

  const CustomGenderPicker({
    super.key,
    required this.initialGender,
    required this.onGenderChanged,
  });

  @override
  State<CustomGenderPicker> createState() => _CustomGenderPickerState();
}

class _CustomGenderPickerState extends State<CustomGenderPicker> {
  late FixedExtentScrollController _controller;
  final List<String> _genders = ['男', '女', '保密'];
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _genders.contains(widget.initialGender) 
        ? _genders.indexOf(widget.initialGender) 
        : 2; // 默认保密
    _controller = FixedExtentScrollController(initialItem: _selectedIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListWheelScrollView(
      controller: _controller,
      itemExtent: 45,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        setState(() {
          _selectedIndex = index;
          widget.onGenderChanged(_genders[index]);
        });
      },
      children: _genders.map((gender) => Center(
        child: Text(
          gender,
          style: const TextStyle(fontSize: 20, color: Colors.black),
        ),
      )).toList(),
    );
  }
}
