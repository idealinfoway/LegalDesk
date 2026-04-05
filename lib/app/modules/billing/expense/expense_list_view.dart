import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../utils/font_styles.dart';
import '../../../services/storage_service.dart';

import '../../../data/models/expense_model.dart';
import '../../../data/models/case_model.dart';

class ExpenseListView extends StatelessWidget {
  const ExpenseListView({super.key});

  Future<void> _ensureCoreBoxesOpen() async {
    await StorageService.instance.ensureCoreBoxesOpen();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Expenses", style: FontStyles.poppins(fontWeight: FontWeight.w600)),
      ),
      body: FutureBuilder<void>(
        future: _ensureCoreBoxesOpen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return ValueListenableBuilder(
        valueListenable: Hive.box<ExpenseModel>('expenses').listenable(),
        builder: (context, Box<ExpenseModel> expenseBox, _) {
          final caseBox = Hive.box<CaseModel>('cases');

          final Map<String, List<ExpenseModel>> grouped = {};
          for (var expense in expenseBox.values) {
            grouped.putIfAbsent(expense.caseId, () => []).add(expense);
          }

          if (grouped.isEmpty) {
            return Center(
              child: Text(
                "No expenses recorded yet",
                style: FontStyles.poppins(fontSize: 16, color: theme.hintColor),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.keys.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final caseId = grouped.keys.elementAt(index);
              final expenses = grouped[caseId]!;

              final caseTitle = caseBox.values
                      .firstWhereOrNull((c) => c.id == caseId)
                      ?.title ??
                  "Unknown Case";

              final totalAmount = expenses.fold<double>(
                0,
                (sum, e) => sum + e.amount,
              );

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
                        "Total: ₹${totalAmount.toStringAsFixed(2)}",
                        style: FontStyles.poppins(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                    ),
                    children: expenses.map((expense) {
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                        visualDensity: VisualDensity.adaptivePlatformDensity,
                        title: Text(
                          expense.title,
                          style: FontStyles.poppins(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          "${expense.date.toLocal().toString().split(" ")[0]}",
                          style: FontStyles.poppins(fontSize: 15),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent),
                          onPressed: () async {
                            final confirm = await Get.dialog<bool>(
                              AlertDialog(
                                title: const Text("Delete Expense"),
                                content: const Text("Are you sure you want to delete this expense?"),
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
                              await expense.delete();
                              Get.snackbar("Deleted", "Expense removed");
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
        onPressed: () => Get.toNamed('/add-expense'),
        icon: const Icon(Icons.add),
        label: const Text("Add Expense"),
      ),
    );
  }
}
