import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:legalsteward/app/data/models/time_entry_model.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/case_model.dart';
import '../../services/storage_service.dart';

class AddTimeEntryView extends StatefulWidget {
  final String? initialCaseId;

  const AddTimeEntryView({super.key, this.initialCaseId});

  @override
  State<AddTimeEntryView> createState() => _AddTimeEntryViewState();
}

class _AddTimeEntryViewState extends State<AddTimeEntryView> {
  final StorageService _storage = StorageService.instance;
  final _formKey = GlobalKey<FormState>();
  final _descController = TextEditingController();
  final _hoursController = TextEditingController();
  final _rateController = TextEditingController();

  String? _selectedCaseId;
  DateTime _selectedDate = DateTime.now();

  List<CaseModel> caseList = <CaseModel>[];

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    final caseBox = await _storage.getBox<CaseModel>('cases');
    final cases = caseBox.values.toList();
    if (!mounted) return;
    setState(() {
      caseList = cases;
      final preselected = widget.initialCaseId;
      if (preselected != null && cases.any((c) => c.id == preselected)) {
        _selectedCaseId = preselected;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final timeEntry = TimeEntryModel(
      id: const Uuid().v4(),
      caseId: _selectedCaseId!,
      date: _selectedDate,
      description: _descController.text.trim(),
      hours: double.parse(_hoursController.text),
      rate: double.parse(_rateController.text),
    );

    final timeEntryBox = await _storage.getBox<TimeEntryModel>('time_entries');
    await timeEntryBox.add(timeEntry);

    Get.back();
    Get.snackbar("Success", "Time entry saved");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Time Entry")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCaseId,
                decoration: const InputDecoration(labelText: "Select Case"),
                items: caseList.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.title));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCaseId = val),
                validator: (val) => val == null ? "Please select a case" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Enter description" : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hoursController,
                decoration: const InputDecoration(
                  labelText: "Hours (e.g. 1.5)",
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) => val == null || double.tryParse(val) == null
                    ? "Enter valid number"
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _rateController,
                decoration: const InputDecoration(labelText: "Rate (per hour)"),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (val) => val == null || double.tryParse(val) == null
                    ? "Enter valid rate"
                    : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Date"),
                subtitle: Text("${_selectedDate.toLocal()}".split(' ')[0]),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: _pickDate,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text("Save Time Entry"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
