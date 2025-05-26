import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DatePickerWidget extends StatefulWidget {
  final ValueChanged<DateTime> onDateSelected;
  final String? labelText;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DatePickerWidget({
    Key? key,
    required this.onDateSelected,
    this.labelText = 'Select Date',
    this.initialDate,
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  _DatePickerWidgetState createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  late TextEditingController _dateController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController();
    _selectedDate = widget.initialDate;
    if (_selectedDate != null) {
      _dateController.text = _formatDate(_selectedDate!);
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(2000),
      lastDate: widget.lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = _formatDate(picked);
      });
      widget.onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _dateController,
      decoration: InputDecoration(
        labelText: widget.labelText,
        suffixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      readOnly: true,
      onTap: () => _selectDate(context),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a date';
        }
        return null;
      },
    );
  }
}
