import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:legalsteward/app/modules/about/view.dart';
import 'package:legalsteward/app/modules/ads/banner_ad_implement.dart';
import 'package:legalsteward/app/modules/dashboard/controller.dart';
import 'package:legalsteward/app/modules/login/controller.dart';
import 'package:legalsteward/app/utils/tools.dart';
import 'package:share_plus/share_plus.dart';

import '../../constants/ad_constant.dart';
import '../../data/models/case_model.dart';
import '../../data/models/client_model.dart';
import '../../data/models/task_model.dart';
import '../tasks/task_controller.dart';
import '../tasks/task_detail_view.dart';
import 'profile_page.dart';

class DashboardView extends GetView<DashBoardController> {
  const DashboardView({super.key});

  Future<void> _handleBackup(BuildContext context) async {
    final loginController = Get.find<LoginController>();
    BuildContext currentContext = context;

    // Record when backup starts
    final startTime = DateTime.now();

    // Show the loading dialog
    try {
      Get.dialog(
        // context: currentContext,
        barrierDismissible: false,
        // builder: (_) =>
        const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Backing up... Please wait'),
            ],
          ),
        ),
      );
    } catch (_) {}

    try {
      GoogleSignInAccount? googleUser;

      try {
        googleUser = await loginController.googleSignIn.signInSilently();
        if (googleUser == null) {
          return _showError(currentContext,
              'Please sign in to Google Drive first', startTime);
        }
      } on PlatformException catch (e) {
        if (e.code == 'network_error') {
          return _showError(currentContext,
              'No internet connection. Please check your network.', startTime);
        }
        rethrow;
      } on SocketException {
        return _showError(
            currentContext, 'Network connection failed.', startTime);
      } on TimeoutException {
        return _showError(currentContext, 'Connection timed out.', startTime);
      }

      try {
        final authHeaders = await googleUser.authHeaders;
        final client = GoogleAuthClient(authHeaders);
        await loginController.backupToDrive(client);
      } on PlatformException catch (e) {
        if (e.code == 'network_error') {
          return _showError(
              currentContext, 'Network error during backup.', startTime);
        }
        rethrow;
      } on SocketException {
        return _showError(
            currentContext, 'Network error during backup.', startTime);
      } on TimeoutException {
        return _showError(currentContext, 'Backup timed out.', startTime);
      } on HttpException {
        return _showError(currentContext, 'Server error occurred.', startTime);
      }

      await _closeDialogAfterMinimumDuration(startTime);
      _showSnackbar('Backup completed successfully!', isError: false);
    } catch (e) {
      await _closeDialogAfterMinimumDuration(startTime);
      _showSnackbar(_mapError(e), isError: true);
    }
  }

  void _closeDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  void _showError(
      BuildContext context, String message, DateTime startTime) async {
    await _closeDialogAfterMinimumDuration(startTime);
    _showSnackbar(message, isError: true);
  }

  Future<void> _closeDialogAfterMinimumDuration(DateTime startTime) async {
    final elapsed = DateTime.now().difference(startTime);
    const minDuration = Duration(seconds: 4);

    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    _closeDialog(); // Close the dialog safely
  }

  void _showSnackbar(String message, {required bool isError}) {
    Get.snackbar(
      isError ? 'Error' : 'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
      colorText: Colors.white,
      duration: Duration(seconds: isError ? 4 : 2),
      icon: Icon(
        isError ? Icons.error_outline : Icons.check_circle_outline,
        color: Colors.white,
      ),
      margin: const EdgeInsets.all(8),
      borderRadius: 8,
    );
  }

  String _mapError(dynamic error) {
    final message = error.toString().toLowerCase();
    if (message.contains('socket') || message.contains('network')) {
      return 'Network connection issue. Please check your internet.';
    } else if (message.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (message.contains('permission')) {
      return 'Permission denied. Please check app permissions.';
    } else if (message.contains('googleapis')) {
      return 'Google services unavailable.';
    }
    return 'Backup failed. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // You can get the controller if you want, or just read directly from Hive here
    final taskController = Get.find<TaskController>();

    return Scaffold(
      appBar: AppBar(
          centerTitle: true,
          title: Text(
            'Dashboard',
            style: Tools.oswaldValue(context).copyWith(color: Colors.white),
          ),
          leading: IconButton(
              onPressed: () {
                Get.to(() => const ProfilePage());
              },
              icon: Icon(Icons.person_outline)),
          actions: [
            PopupMenuButton(
                icon: Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'About') {
                    Get.to(() => AboutPage());
                  } else if (value == 'Sign Out') {
                    final loginController = Get.isRegistered<LoginController>()
                        ? Get.find<LoginController>()
                        : Get.put(LoginController(), permanent: true);
                    loginController.signOut();
                  } else if (value == 'Share') {
                    SharePlus.instance.share(
                      ShareParams(
                        subject: 'Check out this App!',
                        text:
                            'Check out my app: https://play.google.com/store/apps/details?id=mhc.file.mhcdb',
                        title: 'Check out this App',
                      ),
                    );
                  } else {
                    SystemNavigator.pop();
                  }
                },
                itemBuilder: (context) => [
                      PopupMenuItem(value: 'About', child: Text('About')),
                      PopupMenuItem(value: 'Share', child: Text('Share')),
                      PopupMenuItem(value: 'Sign Out', child: Text('Sign Out')),
                      PopupMenuItem(value: 'Exit', child: Text('Exit')),
                    ])
          ]),
      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Row(
                    spacing: 16,
                    children: <Widget>[
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable:
                              Hive.box<CaseModel>('cases').listenable(),
                          builder: (context, Box<CaseModel> caseBox, _) {
                            return DashboardCard(
                              title: 'Cases',
                              value: '${caseBox.length}',
                              icon: Icons.gavel,
                              onTap: () => Get.toNamed('/cases'),
                              color: Colors.indigo,
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable:
                              Hive.box<ClientModel>('clients').listenable(),
                          builder: (context, Box<ClientModel> clientBox, _) {
                            return DashboardCard(
                              title: 'Clients',
                              value: '${clientBox.length}',
                              icon: Icons.person,
                              onTap: () => Get.toNamed('/clients'),
                              color: Colors.teal,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    spacing: 16,
                    children: <Widget>[
                      Expanded(
                        child: NormalCard(
                          title: 'Calendar',
                          icon: Icons.calendar_month,
                          onTap: () => Get.toNamed('/calendar'),
                          color: const Color.fromARGB(255, 94, 112, 217),
                        ),
                      ),
                      Expanded(
                        child: NormalCard(
                          title: 'Billing',
                          icon: Icons.currency_rupee_outlined,
                          onTap: () => Get.toNamed('/billing'),
                          color: const Color.fromARGB(255, 94, 112, 217),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 2,
                    borderOnForeground: true,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => Get.toNamed('/tasks'),
                            child: Text(
                              "Tasks To Do",
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontFamily: 'oswald',
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                                // decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ValueListenableBuilder(
                            valueListenable:
                                Hive.box<TaskModel>('tasks').listenable(),
                            builder: (context, Box<TaskModel> taskBox, _) {
                              final tasks = taskBox.values
                                  .where((t) => !t.isCompleted)
                                  .toList();
        
                              if (tasks.isEmpty) {
                                return GestureDetector(
                                  onTap: () => Get.toNamed('/tasks'),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withAlpha((0.05 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: theme.colorScheme.primary),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.add_task,
                                            color: Colors.blueAccent),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "No pending tasks — Add Task",
                                            style:
                                                theme.textTheme.bodyLarge?.copyWith(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
        
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: tasks.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final task = tasks[index];
        
                                  return GestureDetector(
                                    onTap: () =>
                                        Get.to(() => TaskDetailView(task: task)),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: theme.cardColor,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withAlpha((0.05 * 255).toInt()),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.check_circle_outline,
                                              color: theme.colorScheme.primary),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              task.title,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const Icon(Icons.arrow_forward_ios,
                                              size: 16),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // adhere
                  // RefreshableBannerAdWidget(adUnitId: 'ca-app-pub-3940256099942544/9214589741'),
                  RefreshableBannerAdWidget(adUnitId: AdConstant.bannerAdUnitId),
                  
                  const SizedBox(height: 42),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Obx(() {
                  final connected = controller.isConnected.value;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Debug indicator (you can remove this later)
                      if (!connected)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Offline',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.backup),
                        label: Text(
                          connected ? 'Backup Now' : 'No Internet',
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 40),
                          backgroundColor: connected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        onPressed: (connected && !controller.isBackingUp.value)
                            ? () async {
                                controller.isBackingUp.value = true;
                                await _handleBackup(context);
                                await Future.delayed(const Duration(seconds: 4));
                                controller.isBackingUp.value = false;
                              }
                            : null,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha((0.9 * 255).toInt()),
          borderRadius: BorderRadius.circular(20),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        icon,
                        size: size.width * 0.12,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: Tools.oswaldValue(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: Tools.oswaldValue(context).copyWith(
                        fontSize: size.width * 0.12,
                        // color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class NormalCard extends StatelessWidget {
  final String title;
  // final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const NormalCard({
    super.key,
    required this.title,
    // required this.value,
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha((0.9 * 255).toInt()),
          borderRadius: BorderRadius.circular(20),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        // weight: 10,
                        size: size.width * 0.12,
                        color: Theme.of(context).colorScheme.onError,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        style: Tools.oswaldValue(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Flexible(
                //   flex: 1,
                //   child: FittedBox(
                //     fit: BoxFit.scaleDown,
                //     child: Text(
                //       value,
                //       style: Tools.oswaldValue(context).copyWith(
                //         fontSize: size.width * 0.12,
                //         // color: Colors.white,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            );
          },
        ),
      ),
    );
  }
}
