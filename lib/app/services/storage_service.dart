import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/models/case_model.dart';
import '../data/models/client_model.dart';
import '../data/models/expense_model.dart';
import '../data/models/hearing_model.dart';
import '../data/models/invoice_model.dart';
import '../data/models/task_model.dart';
import '../data/models/time_entry_model.dart';
import '../data/models/user_model.dart';

class StorageService {
  StorageService._();

  static final StorageService instance = StorageService._();

  static const List<String> coreBoxNames = <String>[
    'user',
    'cases',
    'clients',
    'tasks',
    'time_entries',
    'expenses',
    'invoices',
    'hearings',
  ];

  static const String _appMetaBoxName = 'app_meta';
  static const String _legacyCaseSnapshotMigrationKey =
      'legacy_case_snapshot_to_hearing_v1_done';
  static const String _legacyMigratedSummary = 'Migrated from case details';

  Future<Box<T>> getBox<T>(String name) async {
    try {
      if (Hive.isBoxOpen(name)) {
        return Hive.box<T>(name);
      }
      return await Hive.openBox<T>(name);
    } catch (_) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).close();
      }
      return await Hive.openBox<T>(name);
    }
  }

  Future<void> ensureCoreBoxesOpen() async {
    await Future.wait(<Future<void>>[
      _openUser(),
      _openCases(),
      _openClients(),
      _openTasks(),
      _openTimeEntries(),
      _openExpenses(),
      _openInvoices(),
      _openHearings(),
    ]);
  }

  Future<void> flushCoreBoxes() async {
    final userBox = await getBox<UserModel>('user');
    final casesBox = await getBox<CaseModel>('cases');
    final clientsBox = await getBox<ClientModel>('clients');
    final tasksBox = await getBox<TaskModel>('tasks');
    final timeEntriesBox = await getBox<TimeEntryModel>('time_entries');
    final expensesBox = await getBox<ExpenseModel>('expenses');
    final invoicesBox = await getBox<InvoiceModel>('invoices');
    final hearingsBox = await getBox<hearingModel>('hearings');

    await Future.wait(<Future<void>>[
      userBox.flush(),
      casesBox.flush(),
      clientsBox.flush(),
      tasksBox.flush(),
      timeEntriesBox.flush(),
      expensesBox.flush(),
      invoicesBox.flush(),
      hearingsBox.flush(),
    ]);
  }

  Future<void> clearCoreBoxes() async {
    final userBox = await getBox<UserModel>('user');
    final casesBox = await getBox<CaseModel>('cases');
    final clientsBox = await getBox<ClientModel>('clients');
    final tasksBox = await getBox<TaskModel>('tasks');
    final timeEntriesBox = await getBox<TimeEntryModel>('time_entries');
    final expensesBox = await getBox<ExpenseModel>('expenses');
    final invoicesBox = await getBox<InvoiceModel>('invoices');
    final hearingsBox = await getBox<hearingModel>('hearings');

    await Future.wait(<Future<void>>[
      userBox.clear(),
      casesBox.clear(),
      clientsBox.clear(),
      tasksBox.clear(),
      timeEntriesBox.clear(),
      expensesBox.clear(),
      invoicesBox.clear(),
      hearingsBox.clear(),
    ]);
  }

  Future<void> closeCoreBoxesSafely() async {
    await Future.wait(<Future<void>>[
      _closeIfOpen<UserModel>('user'),
      _closeIfOpen<CaseModel>('cases'),
      _closeIfOpen<ClientModel>('clients'),
      _closeIfOpen<TaskModel>('tasks'),
      _closeIfOpen<TimeEntryModel>('time_entries'),
      _closeIfOpen<ExpenseModel>('expenses'),
      _closeIfOpen<InvoiceModel>('invoices'),
      _closeIfOpen<hearingModel>('hearings'),
    ]);
  }

  /// Repairs stale absolute attachment paths after restore.
  ///
  /// Old devices can persist absolute paths that no longer exist after login
  /// restore. This remaps broken entries to files restored into the current
  /// app documents directory using their basename.
  Future<int> repairAttachmentPathsAfterRestore() async {
    final appDir = await getApplicationDocumentsDirectory();
    final appPath = appDir.path;

    int repairedCount = 0;

    final casesBox = await getBox<CaseModel>('cases');
    for (final c in casesBox.values) {
      final result = _repairAttachmentList(c.attachedFiles, appPath);
      if (!result.changed) continue;

      c.attachedFiles = result.paths;
      await c.save();
      repairedCount += result.repairedCount;
    }

    final hearingsBox = await getBox<hearingModel>('hearings');
    for (final h in hearingsBox.values) {
      final result = _repairAttachmentList(h.attachedFiles, appPath);
      if (!result.changed) continue;

      h.attachedFiles = result.paths;
      await h.save();
      repairedCount += result.repairedCount;
    }

    return repairedCount;
  }

  Future<void> _openUser() async => getBox<UserModel>('user').then((_) {});
  Future<void> _openCases() async => getBox<CaseModel>('cases').then((_) {});
  Future<void> _openClients() async =>
      getBox<ClientModel>('clients').then((_) {});
  Future<void> _openTasks() async => getBox<TaskModel>('tasks').then((_) {});
  Future<void> _openTimeEntries() async =>
      getBox<TimeEntryModel>('time_entries').then((_) {});
  Future<void> _openExpenses() async =>
      getBox<ExpenseModel>('expenses').then((_) {});
  Future<void> _openInvoices() async =>
      getBox<InvoiceModel>('invoices').then((_) {});
  Future<void> _openHearings() async =>
      getBox<hearingModel>('hearings').then((_) {});

  Future<void> migrateLegacyCaseSnapshotToHearings() async {
    final metaBox = await getBox<dynamic>(_appMetaBoxName);
    final alreadyDone =
        metaBox.get(_legacyCaseSnapshotMigrationKey, defaultValue: false) ==
            true;
    if (alreadyDone) {
      return;
    }

    final casesBox = await getBox<CaseModel>('cases');
    final hearingsBox = await getBox<hearingModel>('hearings');

    for (final c in casesBox.values) {
      final legacyNotes = c.notes.trim();
      final legacyNextHearing = c.nextHearing;
      final hasLegacyData = legacyNotes.isNotEmpty || legacyNextHearing != null;
      if (!hasLegacyData) {
        continue;
      }

      final caseHearings = hearingsBox.values.where((h) => h.caseId == c.id);
      final alreadyCaptured = caseHearings.any((h) {
        final existingSummary = h.summary.trim();
        final existingNotes = h.nextHearingNotes?.trim() ?? '';
        final notesMatch =
            existingNotes == legacyNotes || existingSummary == legacyNotes;
        final dateMatch = _sameDay(h.nextHearingDate, legacyNextHearing);
        return notesMatch && dateMatch;
      });

      if (alreadyCaptured) {
        continue;
      }

      await hearingsBox.add(
        hearingModel(
          id: 'legacy-${c.id}-${DateTime.now().microsecondsSinceEpoch}',
          caseId: c.id,
          hearingDate: legacyNextHearing ?? DateTime.now(),
          summary: legacyNotes.isEmpty ? _legacyMigratedSummary : legacyNotes,
          orderNotes: null,
          nextHearingDate: legacyNextHearing,
          nextHearingPurpose: null,
          nextHearingNotes: legacyNotes.isEmpty ? null : legacyNotes,
          attachedFiles: const <String>[],
          extraFields: const <String, dynamic>{
            'source': 'legacy_case_snapshot_migration',
          },
          createdAt: DateTime.now(),
        ),
      );
    }

    await metaBox.put(_legacyCaseSnapshotMigrationKey, true);
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  _AttachmentRepairResult _repairAttachmentList(
    List<String>? original,
    String appPath,
  ) {
    if (original == null || original.isEmpty) {
      return _AttachmentRepairResult(
        paths: original,
        repairedCount: 0,
        changed: false,
      );
    }

    final repaired = <String>[];
    int repairedCount = 0;
    bool changed = false;

    for (final item in original) {
      final sourcePath = item.trim();
      if (sourcePath.isEmpty) {
        repaired.add(item);
        continue;
      }

      if (File(sourcePath).existsSync()) {
        repaired.add(sourcePath);
        if (sourcePath != item) {
          changed = true;
        }
        continue;
      }

      final fileName = p.basename(sourcePath.replaceAll('\\', '/'));
      if (fileName.isEmpty) {
        repaired.add(sourcePath);
        continue;
      }

      final remappedPath = p.join(appPath, fileName);
      if (File(remappedPath).existsSync()) {
        repaired.add(remappedPath);
        repairedCount++;
        changed = true;
      } else {
        repaired.add(sourcePath);
      }
    }

    return _AttachmentRepairResult(
      paths: repaired,
      repairedCount: repairedCount,
      changed: changed,
    );
  }

  Future<void> _closeIfOpen<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box<T>(boxName).close();
    }
  }
}

class _AttachmentRepairResult {
  final List<String>? paths;
  final int repairedCount;
  final bool changed;

  const _AttachmentRepairResult({
    required this.paths,
    required this.repairedCount,
    required this.changed,
  });
}
