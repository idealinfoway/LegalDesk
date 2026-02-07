import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:legalsteward/app/data/models/hearing_model.dart';

import 'app/data/models/case_model.dart';
import 'app/data/models/client_model.dart';
import 'app/data/models/expense_model.dart';
import 'app/data/models/invoice_model.dart';
import 'app/data/models/task_model.dart';
import 'app/data/models/time_entry_model.dart';
import 'app/data/models/user_model.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  await Hive.initFlutter();
  // Local notifications setup
  // await NotificationService.init();
  MobileAds.instance.initialize();
  Hive.registerAdapter(CaseModelAdapter());
  Hive.registerAdapter(hearingModelAdapter());
  Hive.registerAdapter(ClientModelAdapter());
  Hive.registerAdapter(TaskModelAdapter());
  Hive.registerAdapter(TimeEntryModelAdapter());
  Hive.registerAdapter(ExpenseModelAdapter());
  Hive.registerAdapter(InvoiceModelAdapter());
  Hive.registerAdapter(UserModelAdapter());

  await Hive.openBox<InvoiceModel>('invoices');
  await Hive.openBox<TaskModel>('tasks');
  await Hive.openBox<CaseModel>('cases');
  await Hive.openBox<hearingModel>('hearings');
  await Hive.openBox<ClientModel>('clients');
  await Hive.openBox<TimeEntryModel>('time_entries');
  await Hive.openBox<ExpenseModel>('expenses'); 
  await Hive.openBox<UserModel>('user');

  // Schedule a test notification 15 seconds after launch to validate setup.
  // _scheduleStartupTestNotification();

  runApp(const MyApp());
}

/// Schedules a test notification for tomorrow at 9 AM to verify
/// that local notification scheduling works with real-world timing.
/// Remove or comment this out once validation is complete.
// void _scheduleStartupTestNotification() {
//   // Cancel any old test notifications first
//   NotificationService.cancel(99);   // Old 30s test
//   NotificationService.cancel(100);  // Old 2min test
//   NotificationService.cancel(999999); // Old startup test
  
//   // Print diagnostics first
//   NotificationService.printDiagnostics();
  
//   // Test: Schedule for tomorrow at 9:00 AM (realistic case hearing reminder timing)
//   final now = DateTime.now();
//   final tomorrow9AM = DateTime(now.year, now.month, now.day + 1, 9, 0);
  
//   NotificationService.scheduleOneOff(
//     id: 999,
//     title: '⚖️ Test: Tomorrow 9 AM',
//     body: 'This is a test reminder scheduled for tomorrow morning. If you see this, notifications are working!',
//     when: tomorrow9AM,
//   );
  
//   print('[Main] 📅 Test notification scheduled for: $tomorrow9AM');
//   print('[Main] ⏱️ That\'s ${tomorrow9AM.difference(now).inHours} hours from now');
  
//   // Show instant notification for immediate feedback
//   NotificationService.showInstant(
//     id: 992,
//     title: '✅ LegalSteward Started',
//     body: 'Local notifications initialized! Test reminder scheduled for tomorrow 9 AM.',
//   );
  
//   // Print diagnostics again after scheduling
//   Future.delayed(const Duration(seconds: 2), () {
//     NotificationService.printDiagnostics();
//   });
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Legal Desk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme, 
      themeMode: ThemeMode.system, 
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
