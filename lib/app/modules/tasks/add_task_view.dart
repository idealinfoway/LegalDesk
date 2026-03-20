import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../data/models/task_model.dart';
import '../../data/models/case_model.dart';
import '../../services/notification_service.dart';
import 'task_controller.dart';

class AddTaskView extends StatefulWidget {
  const AddTaskView({super.key});

  @override
  State<AddTaskView> createState() => _AddTaskViewState();
}

class _AddTaskViewState extends State<AddTaskView> {
  final controller = Get.find<TaskController>();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  bool _hasReminder = false;
  String? _selectedCaseId;

  List<CaseModel> caseList = [];

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    final box = Hive.isBoxOpen('cases')
        ? Hive.box<CaseModel>('cases')
        : await Hive.openBox<CaseModel>('cases');

    if (!mounted) return;
    setState(() {
      caseList = box.values.toList();
    });
  }

  Future<void> _pickDateTime() async {
  final date = await showDatePicker(
    context: context,
    initialDate: _dueDate,
    firstDate: DateTime.now().add(const Duration(minutes: 2)),
    lastDate: DateTime(2100),
  );

  if (date == null) return;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(_dueDate),
  );

  if (time == null) return;

  setState(() {
    _dueDate = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  });
}


 void _saveTask() async {
  if (!_formKey.currentState!.validate()) return;

  final id = DateTime.now().millisecondsSinceEpoch.remainder(1000000000);

  final task = TaskModel(
    id: id.toString(),
    title: _titleController.text.trim(),
    description: _descController.text.trim(),
    dueDate: _dueDate,
    hasReminder: _hasReminder,
    linkedCaseId: _selectedCaseId,
    isCompleted: false,
  );

  await controller.addTask(task);

  // ⏰ Schedule Notification
  // if (_hasReminder) {
  //   await NotificationService.scheduleNotification(
  //     id: id,
  //     title: "Reminder: ${task.title}",
  //     body: task.description?.isNotEmpty == true
  //         ? task.description!
  //         : 'Your task is due today!',
  //     scheduledDate: _dueDate,
  //   );
  // }

  Get.back();
  Get.snackbar("Success", "Task added successfully!");
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text("Add Task")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Task Title'),
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              ListTile(
                title: const Text("Due Date"),
                subtitle: Text("${_dueDate.toLocal()}".split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateTime,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Link to Case"),
                value: _selectedCaseId,
                items: caseList.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text(c.title),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCaseId = val),
              ),
              // SwitchListTile(
              //   value: _hasReminder,
              //   onChanged: (val) => setState(() => _hasReminder = val),
              //   title: const Text("Enable Reminder"),
              // ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _saveTask,
                icon: const Icon(Icons.save),
                label: const Text("Save Task"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
