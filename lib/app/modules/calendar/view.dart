import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../constants/ad_constant.dart';
import '../../data/models/case_model.dart';
import '../../data/models/task_model.dart';
import '../ads/banner_ad_implement.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  late final Box<CaseModel> caseBox;
  late final Box<TaskModel> taskBox;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<CaseModel>> _caseEvents = {};
  Map<DateTime, List<TaskModel>> _taskEvents = {};

  final DateFormat _headerDateFormat = DateFormat('EEEE, MMMM d, yyyy');
   final DateFormat _calendarDayFormat = DateFormat('d');

  @override
  void initState() {
    super.initState();
    caseBox = Hive.box<CaseModel>('cases');
    taskBox = Hive.box<TaskModel>('tasks');
    _selectedDay = _focusedDay;
    _loadEvents();
  }

  void _loadEvents() {
    final cases = caseBox.values.toList();
    final Map<DateTime, List<CaseModel>> caseEvents = {};
    for (var c in cases) {
      if (c.nextHearing != null) {
        final date = DateTime(
            c.nextHearing!.year, c.nextHearing!.month, c.nextHearing!.day);
        caseEvents.putIfAbsent(date, () => []).add(c);
      }
    }

     
    final tasks = taskBox.values.toList();
    final Map<DateTime, List<TaskModel>> taskEvents = {};

    for (var task in tasks) {
      final date =
          DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      taskEvents.putIfAbsent(date, () => []).add(task);
    }

    setState(() {
      _caseEvents = caseEvents;
      _taskEvents = taskEvents;
    });
  }

  List<CaseModel> _getCasesForDay(DateTime day) {
    return _caseEvents[DateTime(day.year, day.month, day.day)] ?? [];
  }

  List<TaskModel> _getTasksForDay(DateTime day) {
    return _taskEvents[DateTime(day.year, day.month, day.day)] ?? [];
  }

  
  List<dynamic> _getEventsForDay(DateTime day) {
    final cases = _getCasesForDay(day);
    final tasks = _getTasksForDay(day);
    return [...cases, ...tasks];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          //adhere
                  // RefreshableBannerAdWidget(adUnitId: 'ca-app-pub-3940256099942544/9214589741'),
                  RefreshableBannerAdWidget(adUnitId: AdConstant.bannerAdUnitId),
          TableCalendar<dynamic>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha((0.2 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withAlpha((0.2 * 255).toInt()),
                shape: BoxShape.circle,
              ),
              markersAlignment: Alignment.bottomCenter,
              markerSize: 6,
              weekendTextStyle: TextStyle(color: theme.colorScheme.secondary),
              outsideDaysVisible: false,
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextFormatter: (date, locale) =>
                  DateFormat('MMMM yyyy').format(date),
              leftChevronIcon:
                  Icon(Icons.chevron_left, color: theme.colorScheme.primary),
              rightChevronIcon:
                  Icon(Icons.chevron_right, color: theme.colorScheme.primary),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isNotEmpty) {
                  final cases = _getCasesForDay(date);
                  final tasks = _getTasksForDay(date);

                  
                  if (isSameDay(_selectedDay, date)) {
                     
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                   
                  if (cases.isNotEmpty) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: List.generate(
                        cases.length > 2 ? 2 : cases.length,
                        (index) => Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  } else if (tasks.isNotEmpty) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: List.generate(
                        tasks.length > 2 ? 2 : tasks.length,
                        (index) => Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1.0),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.secondary
                                    .withAlpha((0.2 * 255).toInt()),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${date.day}',
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return null;
                }
                return null;
              },
              todayBuilder: (context, date, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary
                        .withAlpha((0.2 * 255).toInt()),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              selectedBuilder: (context, date, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${date.day}',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              _headerDateFormat.format(_selectedDay ?? DateTime.now()),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: caseBox.listenable(),
              builder: (context, Box<CaseModel> caseBoxValue, _) {
                return ValueListenableBuilder(
                  valueListenable: taskBox.listenable(),
                  builder: (context, Box<TaskModel> taskBoxValue, __) {
                    final cases =
                        _getCasesForDay(_selectedDay ?? DateTime.now());
                    final tasks =
                        _getTasksForDay(_selectedDay ?? DateTime.now());

                    if (cases.isEmpty && tasks.isEmpty) {
                      return const Center(
                          child: Text('No events on this day.'));
                    }

                    return ListView(
                      children: [
                        
                        if (cases.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.gavel,
                                    color: theme.colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Hearings (${cases.length})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...cases.map((c) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary
                                      .withAlpha((0.15 * 255).toInt()),
                                  child: Icon(Icons.gavel,
                                      color: theme.colorScheme.primary),
                                ),
                                title: Text(
                                  c.title,
                                  style: theme.textTheme.titleMedium,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Client: ${c.clientName}'),
                                    if (c.nextHearing != null)
                                      Text(
                                        'Hearing: ${DateFormat('EEE, MMM d, yyyy').format(c.nextHearing!)}',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.secondary,
                                        ),
                                      ),
                                  ],
                                ),
                              )),
                        ],

                       
                        if (tasks.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Icon(Icons.task_alt,
                                    color: theme.colorScheme.secondary,
                                    size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Tasks (${tasks.length})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...tasks.map((task) => ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: task.isCompleted
                                      ? Colors.green
                                          .withAlpha((0.15 * 255).toInt())
                                      : theme.colorScheme.secondary
                                          .withAlpha((0.15 * 255).toInt()),
                                  child: Icon(
                                    task.isCompleted
                                        ? Icons.check_circle
                                        : Icons.task_alt,
                                    color: task.isCompleted
                                        ? Colors.green
                                        : theme.colorScheme.secondary,
                                  ),
                                ),
                                title: Text(
                                  task.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    decoration: task.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (task.description != null)
                                      Text(task.description!),
                                    Text(
                                      'Due: ${DateFormat('EEE, MMM d, yyyy').format(task.dueDate)}',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                    if (task.linkedCaseId != null)
                                      Text(
                                        'Linked to case',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.primary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: task.hasReminder
                                    ? Icon(Icons.notifications,
                                        color: theme.colorScheme.secondary,
                                        size: 20)
                                    : null,
                              )),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
