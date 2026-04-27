import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:collection/collection.dart';
import '../../../utils/font_styles.dart';
import '../../../services/storage_service.dart';

import '../../../data/models/case_model.dart';
import '../../../data/models/time_entry_model.dart';

class TimeEntryListView extends StatelessWidget {
  const TimeEntryListView({super.key});

  Future<void> _ensureCoreBoxesOpen() async {
    await StorageService.instance.ensureCoreBoxesOpen();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text("Time Entries", style: FontStyles.poppins(fontWeight: FontWeight.w600, color: colorScheme.onPrimary)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.9),
                colorScheme.secondary.withValues(alpha: 0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 1,
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
      ),
      body: FutureBuilder<void>(
        future: _ensureCoreBoxesOpen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return ValueListenableBuilder(
        valueListenable: Hive.box<TimeEntryModel>('time_entries').listenable(),
        builder: (context, Box<TimeEntryModel> timeBox, _) {
          final caseBox = Hive.box<CaseModel>('cases');

          final Map<String, List<TimeEntryModel>> grouped = {};
          for (var entry in timeBox.values) {
            grouped.putIfAbsent(entry.caseId, () => []).add(entry);
          }

          if (grouped.isEmpty) {
            return Center(
              child: Text("No time entries added yet",
                  style: FontStyles.poppins(fontSize: 16, color: theme.hintColor)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.keys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final caseId = grouped.keys.elementAt(index);
              final entries = grouped[caseId]!;
              final caseTitle = caseBox.values.firstWhereOrNull((c) => c.id == caseId)?.title ?? "Unknown Case";

              final totalHours = entries.fold<double>(0, (sum, e) => sum + e.hours);
              final totalAmount = entries.fold<double>(0, (sum, e) => sum + e.total);

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                color: theme.cardColor,
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    visualDensity: VisualDensity.adaptivePlatformDensity,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    title: Text(
                      caseTitle,
                      style: FontStyles.poppins(fontWeight: FontWeight.w600, fontSize: 20),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Total Hours: ${totalHours.toStringAsFixed(2)} • ₹${totalAmount.toStringAsFixed(2)}",
                        style: FontStyles.poppins(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                    children: entries.map((entry) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        title: Text(entry.description,
                            style: FontStyles.poppins(fontSize: 16, fontWeight: FontWeight.w500)),
                            visualDensity: VisualDensity.adaptivePlatformDensity,
                        subtitle: Text(
                          "${entry.date.toLocal().toString().split(" ")[0]} • ${entry.hours} hrs @ ₹${entry.rate}/hr",
                          style: FontStyles.poppins(fontSize: 15,),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await Get.dialog<bool>(
                              AlertDialog(
                                title: const Text("Delete Entry"),
                                content: const Text("Are you sure you want to delete this time entry?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(result: false),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Get.back(result: true),
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await entry.delete();
                              Get.snackbar("Deleted", "Time entry removed");
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        },
      );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/add-time-entry'),
        icon: const Icon(Icons.add),
        label: const Text("Add Entry"),
      ),
    );
  }
}
