import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/models/case_model.dart';
import '../../data/models/task_model.dart';
import '../../services/storage_service.dart';
import '../cases/case_detail_view.dart';
import 'task_controller.dart';

class TaskDetailView extends StatefulWidget {
  final TaskModel task;
  const TaskDetailView({super.key, required this.task});

  @override
  State<TaskDetailView> createState() => _TaskDetailViewState();
}

class _TaskDetailViewState extends State<TaskDetailView> {
  final TaskController controller = Get.find<TaskController>();
  final StorageService _storage = StorageService.instance;

  @override
  void initState() {
    super.initState();
    controller.loadTasks();
  }

  Future<void> _openLinkedCase() async {
    final linkedCaseId = widget.task.linkedCaseId;
    if (linkedCaseId == null || linkedCaseId.isEmpty) {
      return;
    }

    final caseBox = await _storage.getBox<CaseModel>('cases');
    CaseModel? linkedCase;
    for (final c in caseBox.values) {
      if (c.id == linkedCaseId) {
        linkedCase = c;
        break;
      }
    }

    if (linkedCase == null) {
      Get.snackbar(
        'Case Not Found',
        'The linked case no longer exists.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    Get.to(() => CaseDetailView(caseData: linkedCase!));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formattedDate = DateFormat.yMMMMd().format(
      widget.task.dueDate.toLocal(),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Task Details",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
            letterSpacing: 0.5,
            fontFamily: 'poppins',
          ),
        ),

        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card container for task info
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.task.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (widget.task.description != null &&
                        widget.task.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        widget.task.description!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Due date row
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          color: colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          "Due: $formattedDate",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Completed toggle
                    Obx(() {
                      final updatedTask = controller.tasks.firstWhere(
                        (t) => t.key == widget.task.key,
                        orElse: () => widget.task,
                      );

                      return Row(
                        children: [
                          Text(
                            "Completed:",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Switch(
                            activeThumbColor: colorScheme.primary,
                            value: updatedTask.isCompleted,
                            onChanged: (val) async {
                              updatedTask.isCompleted = val;
                              await controller.updateTask(updatedTask);
                              await controller.loadTasks();
                              Get.snackbar(
                                "Task Updated",
                                val
                                    ? "Marked as completed"
                                    : "Marked as incomplete",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: Colors.black87,
                                colorText: Colors.white,
                                margin: const EdgeInsets.all(12),
                                duration: const Duration(seconds: 2),
                              );
                            },
                          ),
                        ],
                      );
                    }),
                    if (widget.task.linkedCaseId != null) ...[
                      // const SizedBox(height: 24),
                      
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openLinkedCase,
                          icon: const Icon(Icons.open_in_new_rounded),
                          label: const Text('Go to Linked Case'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// void fetchCase() {
//   caseTitle =
// }
