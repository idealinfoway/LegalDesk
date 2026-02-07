import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../data/models/case_model.dart';
import '../../../data/models/hearing_model.dart';
import 'add_hearing.dart';
import 'hearing_detail_view.dart';

class HearingHistoryView extends StatelessWidget {
  final CaseModel caseData;

  const HearingHistoryView({super.key, required this.caseData});

  void _addHearing() {
    Get.to(() => AddHearingView(caseData: caseData))!.then((result) {
      if (result == 'hearing_added') {
        // print("should go back to tab");
        // Get.back(); // Now this pops CaseDetailView
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyBox = Hive.box<hearingModel>('hearings');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hearing History",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            Text(
              caseData.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: _addHearing,
              icon: const Icon(Icons.add_circle_outline, size: 28),
              tooltip: 'Add Hearing',
            ),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: historyBox.listenable(),
        builder: (context, Box<hearingModel> box, _) {
          final hearings =
              box.values.where((h) => h.caseId == caseData.id).toList()
                ..sort((a, b) => b.hearingDate.compareTo(a.hearingDate));

          if (hearings.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No hearings added yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap the + button to add a hearing",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: hearings.length,
            itemBuilder: (context, index) {
              final hearing = hearings[index];
              final isToday = _isToday(hearing.hearingDate);
              final isPast = hearing.hearingDate.isBefore(DateTime.now()) && !isToday;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDark 
                          ? Colors.black.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Get.to(() => HearingDetailView(hearing: hearing));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Date Badge
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isToday
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                  : isPast
                                      ? Colors.grey.withOpacity(0.1)
                                      : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : isPast
                                        ? Colors.grey
                                        : Colors.orange,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  hearing.hearingDate.day.toString(),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isToday
                                        ? Theme.of(context).colorScheme.primary
                                        : isPast
                                            ? Colors.grey
                                            : Colors.orange,
                                  ),
                                ),
                                Text(
                                  _getMonthAbbr(hearing.hearingDate.month),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isToday
                                        ? Theme.of(context).colorScheme.primary
                                        : isPast
                                            ? Colors.grey
                                            : Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "${hearing.hearingDate.day}/${hearing.hearingDate.month}/${hearing.hearingDate.year}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (isToday) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          "Today",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  hearing.summary.isEmpty 
                                      ? "No summary" 
                                      : hearing.summary,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark 
                                        ? Colors.grey[400] 
                                        : Colors.grey[700],
                                    height: 1.3,
                                  ),
                                ),
                                if (hearing.nextHearingDate != null) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.event_available,
                                        size: 14,
                                        color: Colors.green[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Next: ${hearing.nextHearingDate!.day}/${hearing.nextHearingDate!.month}/${hearing.nextHearingDate!.year}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.green[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getMonthAbbr(int month) {
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
    ];
    return months[month - 1];
  }
}