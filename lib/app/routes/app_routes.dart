import 'package:get/get.dart';
import 'package:legalsteward/app/modules/billing/add_time_entry_view.dart';
import 'package:legalsteward/app/modules/billing/expense/expense_list_view.dart';
import 'package:legalsteward/app/modules/billing/invoice/invoiceListView.dart';
import 'package:legalsteward/app/modules/cases/add_cases_view.dart';
import 'package:legalsteward/app/modules/dashboard/binding.dart';

import '../modules/billing/billing_overview_view.dart';
import '../modules/billing/expense/add_expense_view.dart';
import '../modules/billing/invoice/addInvoiceView.dart';
import '../modules/billing/timeEntry/timeEntryListView.dart';
import '../modules/calendar/view.dart';
import '../modules/cases/case_binding.dart';
import '../modules/cases/view.dart';
import '../modules/clients/add_client_view.dart';
import '../modules/clients/client_binding.dart';
import '../modules/clients/view.dart';
import '../modules/dashboard/view.dart';
import '../modules/login/binding.dart';
import '../modules/login/view.dart';
import '../modules/splash/binding.dart';
import '../modules/splash/view.dart';
import '../modules/tasks/add_task_view.dart';
import '../modules/tasks/view.dart';

class AppPages {
  static const initial = '/splash';

  static final routes = [
    GetPage(
      name: '/splash',
      page: () => const SplashView(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: '/login',
      page: () => const LoginView(),
      binding: LoginBinding(),
      // transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: '/dashboard',
      page: () => DashboardView(),
      bindings: [DashBoardBinding(),LoginBinding()],
      // transition: Transition.,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: '/cases',
      page: () => const CasesView(),
      binding: CaseBinding(),
      // transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: '/add-case',
      page: () => const AddCaseView(),
      // transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: '/clients',
      page: () => const ClientsView(),
      binding: ClientBinding(),
      // transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: '/add-client',
      page: () => AddClientView(),
      // transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: '/edit-client',
      page: () => AddClientView(),
      // transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: '/calendar',
      page: () => const CalendarView(),
      // transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: '/tasks',
      page: () => TaskListView(),
      // transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: '/add-task',
      page: () => const AddTaskView(),
      // transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: '/add-time-entry',
      page: () => const AddTimeEntryView(),
      // transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: '/time-entries',
      page: () => const TimeEntryListView(),
      // transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: '/add-expense',
      page: () => const AddExpenseView(),
      // transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: '/expense-list',
      page: () => const ExpenseListView(),
      // transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: '/billing',
      page: () => const BillingOverviewView(),
      // transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: '/invoice-list',
      page: () => const InvoiceListView(),
      // transition: Transition.rightToLeftWithFade,
      transitionDuration: const Duration(milliseconds: 250),
    ),
    GetPage(
      name: '/add-invoice',
      page: () => const AddInvoiceView(),
      // transition: Transition.downToUp,
      transitionDuration: const Duration(milliseconds: 200),
    ),

  ];
}
