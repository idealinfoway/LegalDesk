import 'dart:async';

import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../data/models/task_model.dart';
import '../../services/storage_service.dart';

class TaskController extends GetxController {
  final StorageService _storage = StorageService.instance;
  var tasks = <TaskModel>[].obs;
  Box<TaskModel>? _taskBox;
  StreamSubscription<BoxEvent>? _taskBoxSubscription;

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  @override
  void onClose() {
    _taskBoxSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initialize() async {
    await _ensureTaskBoxOpen();
    await loadTasks();
  }

  Future<Box<TaskModel>> _ensureTaskBoxOpen() async {
    final box = await _storage.getBox<TaskModel>('tasks');

    if (!identical(_taskBox, box)) {
      await _taskBoxSubscription?.cancel();
      _taskBox = box;
      _taskBoxSubscription = box.watch().listen((_) {
        loadTasks();
      });
    }

    return box;
  }

  Future<void> loadTasks() async {
    try {
      final box = await _ensureTaskBoxOpen();
      final allTasks = box.values.toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      tasks.assignAll(allTasks);
    } on HiveError {
      // The box may have been closed during restore/sign-out; reopen and retry once.
      final box = await _storage.getBox<TaskModel>('tasks');
      final allTasks = box.values.toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      tasks.assignAll(allTasks);
    }
  }

  Future<void> addTask(TaskModel task) async {
    final box = await _ensureTaskBoxOpen();
    await box.add(task);
  }

  Future<void> updateTask(TaskModel task) async {
    await _ensureTaskBoxOpen();
    await task.save();
  }

  Future<void> deleteSelected(List<TaskModel> selected) async {
    await _ensureTaskBoxOpen();
    for (var task in selected) {
      await task.delete();
    }
  }
}
