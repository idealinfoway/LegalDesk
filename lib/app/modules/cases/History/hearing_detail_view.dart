import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/hearing_model.dart';

class HearingDetailView extends StatefulWidget {
  final hearingModel hearing;

  const HearingDetailView({super.key, required this.hearing});

  @override
  State<HearingDetailView> createState() => _HearingDetailViewState();
}

class _HearingDetailViewState extends State<HearingDetailView> {
  late TextEditingController summaryController;
  late TextEditingController orderController;
  late TextEditingController nextNotesController;

  DateTime? nextDate;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    summaryController = TextEditingController(text: widget.hearing.summary);
    orderController =
        TextEditingController(text: widget.hearing.orderNotes ?? "");
    nextNotesController =
        TextEditingController(text: widget.hearing.nextHearingNotes ?? "");
    nextDate = widget.hearing.nextHearingDate;
  }

  @override
  void dispose() {
    summaryController.dispose();
    orderController.dispose();
    nextNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickNextDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: nextDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: widget.hearing.hearingDate.add(const Duration(days: 1)),
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
      setState(() => nextDate = picked);
    }
  }

  Future<void> _pickHearingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.hearing.hearingDate,
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
      setState(() => widget.hearing.hearingDate = picked);
    }
  }

  Future<void> _saveChanges() async {
    widget.hearing.summary = summaryController.text.trim();
    widget.hearing.orderNotes = orderController.text.trim();
    widget.hearing.nextHearingNotes = nextNotesController.text.trim();
    widget.hearing.nextHearingDate = nextDate;

    await widget.hearing.save();

    setState(() => _isEditing = false);

    Get.snackbar(
      "Success",
      "Changes saved successfully",
      backgroundColor: Colors.green[100],
      colorText: Colors.green[900],
      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  void _deleteHearing() {
    Get.defaultDialog(
      title: "Delete Hearing",
      titleStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 60,
              color: Colors.orange[700],
            ),
            const SizedBox(height: 16),
            const Text(
              "Are you sure you want to delete this hearing?",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              "This action cannot be undone.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
      radius: 12,
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: const Text("Cancel"),
      ),
      confirm: ElevatedButton(
        onPressed: () async {
          await widget.hearing.delete();
          Get.back(); // Close dialog
          Get.back(); // Pop detail view
          Get.snackbar(
            "Deleted",
            "Hearing deleted successfully",
            backgroundColor: Colors.red[100],
            colorText: Colors.red[900],
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            snackPosition: SnackPosition.BOTTOM,
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: const Text("Delete"),
      ),
    );
  }

  Widget _buildInfoCard({
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
    final h = widget.hearing;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          "Hearing Details",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (_isEditing)
            TextButton.icon(
              onPressed: () {
                setState(() => _isEditing = false);
                // Reset controllers
                summaryController.text = widget.hearing.summary;
                orderController.text = widget.hearing.orderNotes ?? "";
                nextNotesController.text = widget.hearing.nextHearingNotes ?? "";
                nextDate = widget.hearing.nextHearingDate;
              },
              icon: const Icon(Icons.close, size: 20),
              label: const Text("Cancel"),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          IconButton(
            onPressed: _deleteHearing,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete Hearing',
          ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hearing Date Card
          _buildInfoCard(
            title: "Hearing Date",
            icon: Icons.calendar_today,
            iconColor: Theme.of(context).colorScheme.primary,
            child: InkWell(
              onTap: _isEditing ? _pickHearingDate : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _isEditing
                      ? (isDark ? Colors.grey[800] : Colors.grey[50])
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.event,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "${h.hearingDate.day}/${h.hearingDate.month}/${h.hearingDate.year}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (_isEditing)
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
          _buildInfoCard(
            title: "Summary",
            icon: Icons.description_outlined,
            iconColor: Colors.blue,
            child: _isEditing
                ? TextField(
                    controller: summaryController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: "Enter hearing summary...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
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
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      h.summary.isEmpty ? "No summary provided" : h.summary,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: h.summary.isEmpty ? Colors.grey[600] : null,
                      ),
                    ),
                  ),
          ),

          // Order Notes Card
          _buildInfoCard(
            title: "Orders / Observations",
            icon: Icons.gavel,
            iconColor: Colors.orange,
            child: _isEditing
                ? TextField(
                    controller: orderController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Enter orders or observations...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
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
                  )
                : Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (h.orderNotes?.isEmpty ?? true)
                          ? "No orders or observations"
                          : h.orderNotes!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: (h.orderNotes?.isEmpty ?? true)
                            ? Colors.grey[600]
                            : null,
                      ),
                    ),
                  ),
          ),

          // Next Hearing Date Card
          _buildInfoCard(
            title: "Next Hearing Date",
            icon: Icons.event_available,
            iconColor: Colors.green,
            child: InkWell(
              onTap: _isEditing ? _pickNextDate : null,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: nextDate != null
                        ? Colors.green
                        : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: nextDate != null
                      ? Colors.green.withOpacity(0.05)
                      : (_isEditing
                          ? (isDark ? Colors.grey[800] : Colors.grey[50])
                          : null),
                ),
                child: Row(
                  children: [
                    Icon(
                      nextDate != null
                          ? Icons.event_available
                          : Icons.event_outlined,
                      color: nextDate != null ? Colors.green : Colors.grey[600],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      nextDate == null
                          ? "No next hearing scheduled"
                          : "${nextDate!.day}/${nextDate!.month}/${nextDate!.year}",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            nextDate != null ? FontWeight.w500 : FontWeight.w400,
                        color: nextDate != null ? null : Colors.grey[600],
                      ),
                    ),
                    const Spacer(),
                    if (_isEditing)
                      Icon(
                        nextDate != null ? Icons.edit : Icons.arrow_drop_down,
                        color: Colors.grey[600],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}