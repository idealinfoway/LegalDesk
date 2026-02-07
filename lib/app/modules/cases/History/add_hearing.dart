import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:legalsteward/app/data/models/case_model.dart';
import 'package:legalsteward/app/data/models/hearing_model.dart';
import 'package:uuid/uuid.dart';

class AddHearingView extends StatefulWidget {
  final CaseModel caseData;

  const AddHearingView({super.key, required this.caseData});

  @override
  State<AddHearingView> createState() => _AddHearingViewState();
}

class _AddHearingViewState extends State<AddHearingView> {
  final _summaryController = TextEditingController();
  final _orderController = TextEditingController();
  final _nextNotesController = TextEditingController();

  DateTime hearingDate = DateTime.now();
  DateTime? nextHearingDate;

  Future<void> _pickNextDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: nextHearingDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => nextHearingDate = picked);
    }
  }

  Future<void> _pickHearingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: hearingDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => hearingDate = picked);
    }
  }

  Future<void> _saveHearing() async {
    if (_summaryController.text.trim().isEmpty &&
        _orderController.text.trim().isEmpty) {
      Get.snackbar(
        "Invalid Input",
        "Please enter summary or order notes",
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        icon: const Icon(Icons.error_outline, color: Colors.red),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }

    if (nextHearingDate != null && !nextHearingDate!.isAfter(hearingDate)) {
      Get.snackbar(
        "Invalid Date",
        "Next hearing must be after today's hearing",
        backgroundColor: Colors.orange[100],
        colorText: Colors.orange[900],
        icon: const Icon(Icons.warning_amber, color: Colors.orange),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
      );
      return;
    }

    final hearing = hearingModel(
      id: const Uuid().v4(),
      caseId: widget.caseData.id,
      hearingDate: hearingDate,
      summary: _summaryController.text.trim(),
      orderNotes: _orderController.text.trim(),
      nextHearingDate: nextHearingDate,
      nextHearingPurpose: null,
      nextHearingNotes: _nextNotesController.text.trim(),
      attachedFiles: [],
      extraFields: {},
      createdAt: DateTime.now(),
    );

    await Hive.box<hearingModel>('hearings').add(hearing);

    // Snapshot update only when valid next date
    if (nextHearingDate != null) {
      widget.caseData.nextHearing = nextHearingDate;
      await widget.caseData.save();
    }

    Get.back(result: 'hearing_added');
    
    Get.snackbar(
      "Success",
      "Hearing added successfully",
      backgroundColor: Colors.green[100],
      colorText: Colors.green[900],
      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (iconColor ?? Theme.of(context).colorScheme.primary)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Add Hearing",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Hearing Date Card
                _buildSectionCard(
                  title: "Hearing Date",
                  icon: Icons.calendar_today,
                  iconColor: Theme.of(context).colorScheme.primary,
                  child: InkWell(
                    onTap: _pickHearingDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "${hearingDate.day}/${hearingDate.month}/${hearingDate.year}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Summary Card
                _buildSectionCard(
                  title: "What Happened Today",
                  icon: Icons.description_outlined,
                  iconColor: Colors.blue,
                  child: TextField(
                    controller: _summaryController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Describe the proceedings, arguments presented, or key discussions...",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // Order Notes Card
                _buildSectionCard(
                  title: "Orders / Observations",
                  icon: Icons.gavel,
                  iconColor: Colors.orange,
                  child: TextField(
                    controller: _orderController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Court orders, observations, or directives issued...",
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

                // Next Hearing Date Card
                _buildSectionCard(
                  title: "Next Hearing Date (Optional)",
                  icon: Icons.event_available,
                  iconColor: Colors.green,
                  child: InkWell(
                    onTap: _pickNextDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: nextHearingDate != null
                              ? Colors.green
                              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: nextHearingDate != null
                            ? Colors.green.withOpacity(0.05)
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            nextHearingDate != null
                                ? Icons.event_available
                                : Icons.event_outlined,
                            color: nextHearingDate != null
                                ? Colors.green
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Text(
                            nextHearingDate == null
                                ? "Tap to select next hearing date"
                                : "${nextHearingDate!.day}/${nextHearingDate!.month}/${nextHearingDate!.year}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: nextHearingDate != null
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: nextHearingDate != null
                                  ? null
                                  : Colors.grey[600],
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            nextHearingDate != null
                                ? Icons.edit
                                : Icons.arrow_drop_down,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
          
          // Bottom Save Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveHearing,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "Save Hearing",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}