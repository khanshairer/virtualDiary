import 'package:flutter/material.dart';
import 'star_clipper.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class AverageRatingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Box box = Hive.box('diaryEntries');
    final entries = box.values.toList().cast<Map>();

    // Group entries by month
    final Map<String, List<Map>> grouped = {};
    for (var entry in entries) {
      final date = DateTime.parse(entry['date']);
      final monthKey = DateFormat('MMMM yyyy').format(date); // e.g., May 2025
      grouped.putIfAbsent(monthKey, () => []).add(entry);
    }

    return Scaffold(
      backgroundColor: Colors.blue[900],
      appBar: AppBar(title: Text("Monthly Average Ratings")),
      body:
          grouped.isEmpty
              ? Center(
                child: Text(
                  "No diary entries yet!",
                  style: TextStyle(color: Colors.amber[200], fontSize: 18),
                ),
              )
              : ListView(
                padding: EdgeInsets.all(16),
                children:
                    grouped.entries.map((entry) {
                      final month = entry.key;
                      final ratings =
                          entry.value
                              .map((e) => (e['rating'] as num).toDouble())
                              .toList();
                      final avgRating =
                          ratings.reduce((a, b) => a + b) / ratings.length;

                      return Card(
                        color: Colors.blue[800],
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: Colors.amber[300]!,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                month,
                                style: TextStyle(
                                  color: Colors.amber[300],
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              _buildStarDisplay(avgRating),
                              SizedBox(height: 6),
                              Text(
                                "${avgRating.toStringAsFixed(2)} out of 5",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
    );
  }

  Widget _buildStarDisplay(double rating) {
    return Row(
      children: List.generate(5, (index) {
        double fill = (rating - index).clamp(0.0, 1.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: SizedBox(
            width: 30,
            height: 30,
            child: Stack(
              children: [
                Icon(Icons.star_border, color: Colors.white30, size: 30),
                ClipRect(
                  clipper: StarClipper(fill),
                  child: Icon(Icons.star, color: Colors.amber, size: 30),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
