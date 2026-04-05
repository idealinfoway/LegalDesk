import 'package:hive_flutter/hive_flutter.dart';

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

  Future<void> _closeIfOpen<T>(String boxName) async {
    if (Hive.isBoxOpen(boxName)) {
      await Hive.box<T>(boxName).close();
    }
  }
}
