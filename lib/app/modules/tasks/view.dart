import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../utils/font_styles.dart';
import 'task_controller.dart';
import 'task_detail_view.dart';

class TaskListView extends StatelessWidget {
  TaskListView({super.key});

  final controller = Get.find<TaskController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tasks",
          style: FontStyles.poppins(fontWeight: FontWeight.w600),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withAlpha((0.9 * 255).toInt()), 
                colorScheme.secondary.withAlpha((0.9 * 255).toInt()),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Obx(() {
        final tasks = controller.tasks;
        if (tasks.isEmpty) {
          return Center(
            child: Text(
              "No tasks yet",
              style: theme.textTheme.titleMedium,
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final t = tasks[i];

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              color: t.isCompleted
                  ? colorScheme.surfaceContainerHighest.withAlpha((0.6 * 255).toInt() )
                  : theme.cardColor,
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                title: Text(
                  t.title,
                  style: FontStyles.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    decoration:
                        t.isCompleted ? TextDecoration.lineThrough : null,
                    color: theme.textTheme.titleLarge!.color,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 4),
                       Text("Due: ${DateFormat.yMMMd().format(t.dueDate.toLocal())}",
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: t.isCompleted ? Colors.green : theme.iconTheme.color,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: () {
                        controller.deleteSelected([t]);
                        // Get.snackbar('Deleted', 'Task "${t.title}" removed');
                      },
                    ),
                  ],
                ),
                onTap: () {
                  Get.to(() => TaskDetailView(task: t));
                },
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/add-task'),
        icon: const Icon(Icons.add_task),
        label: const Text("Add Task"),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }
}
