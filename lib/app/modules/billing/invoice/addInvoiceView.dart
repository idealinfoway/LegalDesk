import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/models/time_entry_model.dart';
import '../../../services/storage_service.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/case_model.dart';

class AddInvoiceView extends StatefulWidget {
  final String? initialCaseId;

  const AddInvoiceView({super.key, this.initialCaseId});

  @override
  State<AddInvoiceView> createState() => _AddInvoiceViewState();
}

class _AddInvoiceViewState extends State<AddInvoiceView> {
  String? _selectedCaseId;
  final List<String> _selectedTimeEntryIds = [];
  final List<String> _selectedExpenseIds = [];
  final StorageService _storage = StorageService.instance;
  bool _ready = false;
  List<CaseModel> _cases = <CaseModel>[];
  List<TimeEntryModel> _timeEntries = <TimeEntryModel>[];
  List<ExpenseModel> _expenses = <ExpenseModel>[];

  @override
  void initState() {
    super.initState();
    _initBoxes();
  }

  Future<void> _initBoxes() async {
    final caseBox = await _storage.getBox<CaseModel>('cases');
    final timeBox = await _storage.getBox<TimeEntryModel>('time_entries');
    final expenseBox = await _storage.getBox<ExpenseModel>('expenses');
    final cases = caseBox.values.toList();
    final initialCaseId = widget.initialCaseId;

    if (!mounted) return;
    setState(() {
      _cases = cases;
      _timeEntries = timeBox.values.toList();
      _expenses = expenseBox.values.toList();
      if (initialCaseId != null && cases.any((c) => c.id == initialCaseId)) {
        _selectedCaseId = initialCaseId;
      }
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: const Text("Generate Invoice")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Generate Invoice")),
      body: SingleChildScrollView(
        // physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCaseId,
                decoration: const InputDecoration(labelText: "Select Case"),
                items: _cases.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.title));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCaseId = val),
              ),
              const SizedBox(height: 12),

              if (_selectedCaseId != null) ...[
                const Text(
                  "Time Entries",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ..._timeEntries
                    .where((t) => t.caseId == _selectedCaseId)
                    .map(
                      (t) => CheckboxListTile(
                        title: Text("${t.description} - ₹${t.total}"),
                        value: _selectedTimeEntryIds.contains(t.key.toString()),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedTimeEntryIds.add(t.key.toString());
                            } else {
                              _selectedTimeEntryIds.remove(t.key.toString());
                            }
                          });
                        },
                      ),
                    ),
                const SizedBox(height: 12),
                const Text(
                  "Expenses",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ..._expenses
                    .where((e) => e.caseId == _selectedCaseId)
                    .map(
                      (e) => CheckboxListTile(
                        title: Text("${e.title} - ₹${e.amount}"),
                        value: _selectedExpenseIds.contains(e.key.toString()),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedExpenseIds.add(e.key.toString());
                            } else {
                              _selectedExpenseIds.remove(e.key.toString());
                            }
                          });
                        },
                      ),
                    ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.receipt),
                  label: const Text("Generate Invoice"),
                  onPressed: _generateInvoice,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _generateInvoice() async {
    final timeBox = await _storage.getBox<TimeEntryModel>('time_entries');
    final expenseBox = await _storage.getBox<ExpenseModel>('expenses');

    final selectedTimeEntries = _selectedTimeEntryIds
        .map((id) => timeBox.get(int.parse(id))!)
        .toList();
    final selectedExpenses = _selectedExpenseIds
        .map((id) => expenseBox.get(int.parse(id))!)
        .toList();

    final totalAmount =
        selectedTimeEntries.fold<double>(0, (s, e) => s + e.total) +
        selectedExpenses.fold<double>(0, (s, e) => s + e.amount);

    final invoice = InvoiceModel(
      id: const Uuid().v4(),
      caseId: _selectedCaseId!,
      invoiceDate: DateTime.now(),
      isPaid: false,
      timeEntryIds: _selectedTimeEntryIds,
      expenseIds: _selectedExpenseIds,
      totalAmount: totalAmount,
    );

    final invoiceBox = await _storage.getBox<InvoiceModel>('invoices');
    await invoiceBox.add(invoice);

    Get.back();
    Get.snackbar("Success", "Invoice generated");
  }
}
