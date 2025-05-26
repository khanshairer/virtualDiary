import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'date_picker_widget.dart';
import 'star_clipper.dart';

class DiaryEntry {
  final String description;
  final double rating;
  final double numericValue;
  final DateTime date;

  DiaryEntry({
    required this.description,
    required this.rating,
    required this.numericValue,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'rating': rating,
      'numericValue': numericValue,
      'date': date.toIso8601String(),
    };
  }

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      description: map['description'],
      rating: map['rating'],
      numericValue: map['numericValue'],
      date: DateTime.parse(map['date']),
    );
  }
}

class VerticalSliderWidget extends StatefulWidget {
  final String? initialDescription;
  final double? initialRating;
  final double? initialNumericValue;
  final DateTime? initialDate;
  final int? entryIndex;

  VerticalSliderWidget({
    this.initialDescription,
    this.initialRating,
    this.initialNumericValue,
    this.initialDate,
    this.entryIndex,
  });

  @override
  _VerticalSliderWidgetState createState() => _VerticalSliderWidgetState();
}

class _VerticalSliderWidgetState extends State<VerticalSliderWidget> {
  double _sliderValue = 0.5;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  double _baseValue = 2.5;
  DateTime? _selectedDate;
  late Box _diaryBox;

  @override
  void initState() {
    super.initState();
    _initHive();

    _descriptionController.text = widget.initialDescription ?? '';
    _sliderValue = ((widget.initialRating ?? 2.5) / 5).clamp(0.0, 1.0);

    _baseValue = widget.initialNumericValue ?? 2.5;
    _numberController.text = _baseValue.toStringAsFixed(2);

    _selectedDate = widget.initialDate ?? DateTime.now();
    _dateController.text =
        "Date : ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}";
  }

  Future<void> _initHive() async {
    _diaryBox = await Hive.openBox('diaryEntries');
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.amber[300]!,
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
        _dateController.text =
            "Date : " + DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveToDiary() {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a description')));
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select a date')));
      return;
    }

    final newDateStr =
        _selectedDate!.toIso8601String().split('T')[0]; // only date part

    // Check if another entry with the same date already exists (excluding current index if editing)
    for (int i = 0; i < _diaryBox.length; i++) {
      if (widget.entryIndex != null && i == widget.entryIndex) continue;
      final entry = _diaryBox.getAt(i) as Map;
      final entryDateStr =
          DateTime.parse(entry['date']).toIso8601String().split('T')[0];
      if (entryDateStr == newDateStr) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An entry already exists for this date.')),
        );
        return;
      }
    }

    final diaryEntry = {
      'description': _descriptionController.text,
      'rating': (_sliderValue * 5).clamp(0.0, 5.0),
      'numericValue': double.parse(_numberController.text),
      'date': _selectedDate!.toIso8601String(),
    };

    if (widget.entryIndex != null) {
      _diaryBox.putAt(widget.entryIndex!, diaryEntry);
    } else {
      _diaryBox.add(diaryEntry);
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Diary entry saved!')));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double starRating = _sliderValue * 5;

    return Scaffold(
      backgroundColor: Colors.blue[900],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // 🖊 Writing icon on the left
        title: Text('Add To Diary'),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 5),
                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLength: 180,
                      maxLines: null, // 👈 allow multiline
                      keyboardType: TextInputType.multiline,
                      cursorColor: Colors.amber[600],
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.start,
                      buildCounter: (
                        BuildContext context, {
                        required int currentLength,
                        required bool isFocused,
                        required int? maxLength,
                      }) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // align left
                          children: [
                            SizedBox(height: 40),
                            Divider(color: Colors.grey, thickness: 2),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Describe your day in 180 words',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$currentLength / $maxLength',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },

                      decoration: InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        labelText: 'Add Description',
                        labelStyle: TextStyle(color: Colors.amber[400]),
                        contentPadding: EdgeInsets.all(16),
                        filled: false,
                        constraints: BoxConstraints(
                          minHeight: 100,
                          maxHeight: 220,
                        ),
                        counter: null, // disable default counter
                      ),
                    ),
                  ),

                  SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        double fillAmount = (starRating - index).clamp(0, 1);
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: SizedBox(
                            width: 30,
                            height: 30,
                            child: Stack(
                              children: [
                                Icon(
                                  Icons.star_border,
                                  color: Colors.white54,
                                  size: 30,
                                ),
                                ClipRect(
                                  clipper: StarClipper(fillAmount),
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 30,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.only(left: 80.0),
                    child: SizedBox(
                      width: 150,
                      child: TextField(
                        readOnly: true,
                        controller: _numberController,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(border: InputBorder.none),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 150,
                          child: Text(
                            'Rate Your Day : ',
                            style: TextStyle(
                              color: Colors.amber[300],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: Colors.white,
                              inactiveTrackColor: Colors.white54,
                              thumbColor: Colors.white,
                              overlayColor: Colors.white.withOpacity(0.2),
                              trackHeight: 4,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                              ),
                            ),
                            child: Slider(
                              value: _sliderValue,
                              min: 0,
                              max: 1,
                              onChanged: (newValue) {
                                setState(() {
                                  _sliderValue = newValue.clamp(0.0, 1.0);

                                  // Rating from slider (0 to 5)
                                  double rating = (_sliderValue * 5).clamp(
                                    0.0,
                                    5.0,
                                  );

                                  // Round rating to nearest 0.5
                                  double roundedRating =
                                      (rating * 2).round() / 2.0;

                                  _numberController.text = roundedRating
                                      .toStringAsFixed(2);
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveToDiary,
                      child: Text(
                        "Add To Diary",
                        style: TextStyle(
                          color: Colors.amber[300],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: TextStyle(
                            color: Colors.amber[300],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.calendar_today,
                          color: Colors.amber[300],
                          size: 30,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(),
                        onPressed: () => _selectDate(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
