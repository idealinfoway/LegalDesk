import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/models/case_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/time_entry_model.dart';
import '../../../services/pdf_invoice_service.dart';
import '../../../services/storage_service.dart';
import '../../../utils/font_styles.dart';

class InvoiceDetailView extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailView({super.key, required this.invoice});

  @override
  State<InvoiceDetailView> createState() => _InvoiceDetailViewState();
}

class _InvoiceDetailViewState extends State<InvoiceDetailView> {
  final StorageService _storage = StorageService.instance;
  late Box<TimeEntryModel> timeBox;
  late Box<ExpenseModel> expenseBox;
  late Box<CaseModel> caseBox;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initBoxes();
  }

  Future<void> _initBoxes() async {
    timeBox = await _storage.getBox<TimeEntryModel>('time_entries');
    expenseBox = await _storage.getBox<ExpenseModel>('expenses');
    caseBox = await _storage.getBox<CaseModel>('cases');
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invoice Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final invoice = widget.invoice;
    final caseTitle =
        caseBox.values.firstWhereOrNull((c) => c.id == invoice.caseId)?.title ??
            "Unknown Case";

    final timeEntries = invoice.timeEntryIds
        .map((id) => timeBox.get(int.tryParse(id)))
        .whereType<TimeEntryModel>()
        .toList();

    final expenses = invoice.expenseIds
        .map((id) => expenseBox.get(int.tryParse(id)))
        .whereType<ExpenseModel>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Invoice #${invoice.id.substring(0, 8)}...",
          style: FontStyles.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () async {
              final confirm = await Get.dialog<bool>(
                AlertDialog(
                  title: Text("Delete Invoice", style: FontStyles.poppins()),
                  content: Text(
                    "Are you sure you want to delete this invoice?",
                    style: FontStyles.poppins(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: Text("Cancel", style: FontStyles.poppins()),
                    ),
                    TextButton(
                      onPressed: () => Get.back(result: true),
                      child: Text("Delete",
                          style: FontStyles.poppins(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await invoice.delete();
                Get.back();
                Get.snackbar("Deleted", "Invoice deleted successfully");
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text("Case: $caseTitle",
                style: FontStyles.poppins(
                    fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),

            /// Time Entries Section
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.blue),
                const SizedBox(width: 8),
                Text("Time Entries",
                    style: FontStyles.poppins(
                        fontWeight: FontWeight.w600, fontSize: 17)),
              ],
            ),
            const SizedBox(height: 8),
            ...timeEntries.map(
              (t) => Card(
                child: ListTile(
                  title: Text(t.description,
                      style: FontStyles.poppins(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                    "${t.date.toLocal().toString().split(' ')[0]} • ${t.hours} hrs @ ₹${t.rate}/hr",
                    style: FontStyles.poppins(fontSize: 13),
                  ),
                  trailing: Text("₹${t.total.toStringAsFixed(2)}",
                      style: FontStyles.poppins(fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            if (timeEntries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text("No time entries",
                    style:
                        FontStyles.poppins(fontSize: 13, color: Colors.grey)),
              ),

            const SizedBox(height: 24),

            /// Expenses Section
            Row(
              children: [
                const Icon(Icons.money, color: Colors.green),
                const SizedBox(width: 8),
                Text("Expenses",
                    style: FontStyles.poppins(
                        fontWeight: FontWeight.w600, fontSize: 17)),
              ],
            ),
            const SizedBox(height: 8),
            ...expenses.map(
              (e) => Card(
                child: ListTile(
                  title: Text(e.title,
                      style: FontStyles.poppins(fontWeight: FontWeight.w500)),
                  subtitle: Text(
                      "${e.date.toLocal().toString().split(' ')[0]} • ₹${e.amount.toStringAsFixed(2)}",
                      style: FontStyles.poppins(fontSize: 13)),
                  trailing: const Icon(Icons.receipt_long),
                ),
              ),
            ),
            if (expenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text("No expenses",
                    style:
                        FontStyles.poppins(fontSize: 13, color: Colors.grey)),
              ),

            const Divider(height: 32),

            /// Total
            ListTile(
              title: Text("Total Amount",
                  style: FontStyles.poppins(fontWeight: FontWeight.w600)),
              trailing: Text("₹${invoice.totalAmount.toStringAsFixed(2)}",
                  style: FontStyles.poppins(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),

            /// Paid Switch
            SwitchListTile(
              title: Text("Mark as Paid",
                  style: FontStyles.poppins(fontWeight: FontWeight.w500)),
              value: invoice.isPaid,
              onChanged: (val) {
                setState(() {
                  invoice.isPaid = val;
                  invoice.save();
                });
                Get.snackbar(
                  "Updated",
                  val ? "Invoice marked as paid" : "Invoice marked as unpaid",
                  snackPosition: SnackPosition.BOTTOM,
                );
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text("Export PDF"),
                  onPressed: () async {
                    final pdfData = await PdfInvoiceService.generate(invoice);
                    await Printing.layoutPdf(onLayout: (_) => pdfData);
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.share),
                  label: const Text("Share"),
                  onPressed: () async {
                    final pdfData = await PdfInvoiceService.generate(invoice);
                    final dir = await getTemporaryDirectory();
                    final file = File('${dir.path}/invoice_${invoice.id}.pdf');
                    await file.writeAsBytes(pdfData);
                    await SharePlus.instance.share(
                       ShareParams(
    files: [XFile(file.path)],
    text: "Invoice #${invoice.id}",
    subject: "LegalDesk Invoice",
  
                    ));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
