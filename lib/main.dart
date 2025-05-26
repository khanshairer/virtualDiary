import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart'; // for rootBundle

import 'dart:io';

import 'package:open_file/open_file.dart';
import 'review_system.dart';
import 'average_rating_page.dart';
import 'star_clipper.dart';

//import 'package:digital_journa/utils/star_clipper.dart'; not sure if it works in your system...

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('diaryEntries');
  runApp(Diary());
}

class Diary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Diary',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: DiaryPageWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppTheme {
  static final lightTheme = ThemeData(
    primarySwatch: Colors.indigo,
    colorScheme: ColorScheme.light(
      primary: Colors.indigo,
      secondary: Colors.pinkAccent,
    ),
    scaffoldBackgroundColor: Colors.grey[50],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue[400],
      foregroundColor: Colors.white,
      toolbarTextStyle: TextStyle(
        color: Colors.amber,
        fontWeight: FontWeight.bold,
        fontSize: 26,
      ),
      elevation: 4,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.amber[300],
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue[500],
      foregroundColor: Colors.white,
      elevation: 6,
    ),
  );

  static final darkTheme = ThemeData(
    primarySwatch: Colors.indigo,
    colorScheme: ColorScheme.dark(
      primary: Colors.indigo,
      secondary: Colors.pinkAccent[200]!,
    ),
    scaffoldBackgroundColor: Colors.blue[900],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.blue[400],
      foregroundColor: Colors.white,
      elevation: 4,
      centerTitle: true,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.blue[500],
      foregroundColor: Colors.amber[300]!, // Amber icon
    ),
  );
}

class DiaryPageWidget extends StatefulWidget {
  @override
  _DiaryPageWidgetState createState() => _DiaryPageWidgetState();
}

class _DiaryPageWidgetState extends State<DiaryPageWidget> {
  late Box diaryBox;
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    diaryBox = Hive.box('diaryEntries');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[900],
      appBar: AppBar(
        leading: Icon(Icons.pages),
        title: Text('My Diary'),
        actions: [
          IconButton(icon: Icon(Icons.picture_as_pdf), onPressed: _exportToPdf),
          IconButton(
            icon: Icon(Icons.bar_chart),
            tooltip: 'Average Rating',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AverageRatingPage()),
              );
            },
          ),

          RawMaterialButton(
            onPressed: () => _navigateToAddEntry(context),
            shape: CircleBorder(),
            elevation: 0,
            child: Icon(Icons.add, color: Colors.white),
            fillColor: Colors.transparent,
            constraints: BoxConstraints.tight(Size(40, 40)),
          ),
          RawMaterialButton(
            onPressed: _confirmClearAll,
            shape: CircleBorder(),
            elevation: 0,
            child: Icon(Icons.delete, color: Colors.white),
            fillColor: Colors.transparent,
            constraints: BoxConstraints.tight(Size(40, 40)),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: diaryBox.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return Center(
              child: Text(
                'No diary entries yet!\nTap the + button to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.amber[300]),
              ),
            );
          }

          final Map<String, List<Map>> groupedEntries = {};
          for (int i = 0; i < box.length; i++) {
            final entry = box.getAt(i) as Map;
            final date = DateTime.parse(entry['date']);
            final monthKey = DateFormat('MMMM, yyyy').format(date);
            if (!groupedEntries.containsKey(monthKey)) {
              groupedEntries[monthKey] = [];
            }
            groupedEntries[monthKey]!.add({...entry, 'index': i});
          }

          final allMonths = groupedEntries.keys.toList();

          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(12),
                child: DropdownButton<String>(
                  value: _selectedMonth,
                  hint: Text(
                    "Filter by month",
                    style: TextStyle(color: Colors.amber[300]),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(
                        'Show All',
                        style: TextStyle(color: Colors.amber[300]),
                      ),
                    ),
                    ...allMonths.map((month) {
                      return DropdownMenuItem(value: month, child: Text(month));
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value;
                    });
                  },
                  dropdownColor: Colors.blue[800],
                  style: TextStyle(
                    color: Colors.amber[300],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  children:
                      groupedEntries.entries
                          .where(
                            (group) =>
                                _selectedMonth == null ||
                                group.key == _selectedMonth,
                          )
                          .map((group) {
                            double avgRating = 0;
                            if (group.value.isNotEmpty) {
                              avgRating =
                                  group.value
                                      .map(
                                        (e) => (e['rating'] as num).toDouble(),
                                      )
                                      .reduce((a, b) => a + b) /
                                  group.value.length;
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                                  child: Text(
                                    "${group.key}  (Avg: ${avgRating.toStringAsFixed(1)})",
                                    style: TextStyle(
                                      color: Colors.amber[300],
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ...group.value
                                    .map((entry) => _buildEntryCard(entry))
                                    .toList(),
                              ],
                            );
                          })
                          .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEntryCard(Map entry) {
    return Dismissible(
      key: Key(entry['index'].toString()),
      background: Container(color: Colors.red),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) => _confirmDismiss(entry['index']),
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.amber, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 4,
        color: Colors.blue[700],
        child: ListTile(
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEE, MMM dd').format(DateTime.parse(entry['date'])),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.amber[400],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 20),
              _buildStarRow(entry['rating'], iconSize: 20),
              Spacer(),
              IconButton(
                onPressed: () => _confirmDelete(entry['index']),
                icon: Icon(Icons.delete, color: Colors.amber[400]),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 4),
              Text(
                entry['description'] ?? 'No description',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
            ],
          ),
          onTap: () => _showEntryDetails(context, entry),
        ),
      ),
    );
  }

  Future<void> _navigateToAddEntry(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => VerticalSliderWidget()),
    );
    setState(() {});
  }

  Future<void> _showEntryDetails(BuildContext context, Map entry) async {
    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.blue[800],
            title: Text(
              'Diary Entry',
              style: TextStyle(color: Colors.amber[600]),
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Description:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[600],
                    ),
                  ),
                  Text(
                    entry['description'] ?? 'No description',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[400],
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildDetailRow(
                    Icons.star,
                    'Rating: ${entry['rating']?.toStringAsFixed(1)}',
                  ),
                  _buildDetailRow(
                    Icons.calendar_today,
                    DateFormat(
                      'MMMM dd, yyyy',
                    ).format(DateTime.parse(entry['date'])),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(
                  'Edit',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context); // Close the dialog
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => VerticalSliderWidget(
                            initialDescription: entry['description'],
                            initialRating: entry['rating'],
                            initialNumericValue: entry['numericValue'],
                            initialDate: DateTime.parse(entry['date']),
                            entryIndex: entry['index'],
                          ),
                    ),
                  );
                  setState(() {}); // Refresh list after edit
                },
              ),
              TextButton(
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.amber[400]),
          SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: Colors.amber[400],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRow(double rating, {double iconSize = 16}) {
    return Row(
      children: List.generate(5, (index) {
        double fillAmount = (rating - index).clamp(0.0, 1.0);
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: SizedBox(
            width: iconSize,
            height: iconSize,
            child: Stack(
              children: [
                Icon(Icons.star_border, color: Colors.amber, size: iconSize),
                ClipRect(
                  clipper: StarClipper(fillAmount),
                  child: Icon(Icons.star, color: Colors.amber, size: iconSize),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  String _formatTitleWithRating(String dateStr, double rating) {
    final date = DateTime.parse(dateStr);
    final weekday = DateFormat('EEE').format(date); // Thu
    final month = DateFormat('MMM').format(date); // May
    final day = DateFormat('dd').format(date); // 08

    final fullStars = '★' * rating.floor();
    final halfStar = (rating % 1 >= 0.5) ? '½' : '';

    return "$weekday, $month, $day     $fullStars$halfStar";
  }

  Future<void> _confirmDelete(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Entry'),
            content: Text('Are you sure you want to delete this entry?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await diaryBox.deleteAt(index);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Entry deleted')));
    }
  }

  Future<bool?> _confirmDismiss(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Delete Entry'),
            content: Text('Are you sure you want to delete this entry?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await diaryBox.deleteAt(index);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Entry deleted')));
    }

    return confirmed;
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Clear All Entries'),
            content: Text('This will delete ALL diary entries. Continue?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: Text('Clear All', style: TextStyle(color: Colors.red)),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await diaryBox.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('All entries deleted')));
    }
  }

  Future<void> _exportToPdf() async {
    try {
      final entries = diaryBox.values.toList().cast<Map>();
      if (entries.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No entries to export')));
        return;
      }

      // Load font
      final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      final roboto = pw.Font.ttf(fontData);

      // Fallback font for star icons (if Roboto doesn't render them)
      final starFont = pw.Font.helvetica();

      // Group entries by month
      final groupedEntries = <String, List<Map>>{};
      for (final entry in entries) {
        final date = DateTime.parse(entry['date']);
        final monthKey = DateFormat('MMMM, yyyy').format(date);
        groupedEntries.putIfAbsent(monthKey, () => []).add(entry);
      }

      // Define custom colors
      final backgroundColor = PdfColor.fromInt(0xFF0D47A1.toInt()); // Blue 900
      final cardColor = PdfColor.fromInt(0xFF1976D2.toInt()); // Blue 700
      final amber = PdfColors.amber;
      final white = PdfColors.white;

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4,
            margin: pw.EdgeInsets.all(24),
            buildBackground: (context) => pw.Container(color: backgroundColor),
          ),
          build:
              (context) => [
                pw.Text(
                  'My Diary Entries',
                  style: pw.TextStyle(
                    font: roboto,
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: amber,
                  ),
                ),
                pw.SizedBox(height: 20),
                ...groupedEntries.entries.map((group) {
                  double avgRating =
                      group.value
                          .map((e) => (e['rating'] as num).toDouble())
                          .reduce((a, b) => a + b) /
                      group.value.length;

                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "${group.key} (Avg: ${avgRating.toStringAsFixed(1)})",
                        style: pw.TextStyle(
                          font: roboto,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: amber,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      ...group.value.map((entry) {
                        return pw.Container(
                          margin: pw.EdgeInsets.symmetric(vertical: 6),
                          padding: pw.EdgeInsets.all(8),
                          decoration: pw.BoxDecoration(
                            color: cardColor,
                            border: pw.Border.all(color: amber),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                DateFormat(
                                  'EEE, MMM dd',
                                ).format(DateTime.parse(entry['date'])),
                                style: pw.TextStyle(
                                  font: roboto,
                                  fontSize: 12,
                                  color: amber,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              _buildPdfStarRating(
                                (entry['rating'] as num).toDouble(),
                                font: starFont,
                              ),
                              pw.Text(
                                entry['description'] ?? 'No description',
                                style: pw.TextStyle(
                                  font: roboto,
                                  fontSize: 12,
                                  color: white,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      pw.SizedBox(height: 16),
                    ],
                  );
                }),
              ],
        ),
      );

      // Save and open file
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${dir.path}/diary_export_$timestamp.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('PDF saved to ${file.path}')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
      );
    }
  }

  pw.Widget _buildPdfStarRating(double rating, {required pw.Font font}) {
    final fullStars = '★' * rating.floor();
    final halfStar = (rating % 1 >= 0.5) ? '½' : '';
    final emptyStars = '☆' * (5 - rating.ceil());

    return pw.Text(
      'Rating: $fullStars$halfStar$emptyStars (${rating.toStringAsFixed(1)})',
      style: pw.TextStyle(font: font, fontSize: 14, color: PdfColors.amber),
    );
  }
}
