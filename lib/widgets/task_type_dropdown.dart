import 'package:flutter/material.dart';

const List<String> kTaskCategories = ['Online', 'Physical', 'Student Offers'];

class TaskTypeDropdown extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;

  const TaskTypeDropdown({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<TaskTypeDropdown> createState() => _TaskTypeDropdownState();
}

class _TaskTypeDropdownState extends State<TaskTypeDropdown> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue ?? kTaskCategories.first;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selected,
          dropdownColor: const Color(0xFF1E293B),
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Colors.white38, size: 20),
          items: kTaskCategories.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() => _selected = newValue!);
            widget.onChanged(newValue!);
          },
        ),
      ),
    );
  }
}
