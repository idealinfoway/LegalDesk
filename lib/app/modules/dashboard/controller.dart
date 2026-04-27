

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
// import 'package:flutter/material.dart';

import '../../services/app_update.dart';

class DashBoardController extends GetxController{

  final RxBool isConnected = true.obs;
  final Connectivity _connectivity = Connectivity();
  final isBackingUp = false.obs;


  void _updateConnectionStatus(List<ConnectivityResult> connectivityResult) {
    if (connectivityResult.contains(ConnectivityResult.none)) {
      isConnected.value = false;
      if (!Get.isSnackbarOpen) {
        Future.delayed(Duration.zero, () {
          if (Get.context != null) { // Ensure context is available
            // Get.snackbar(
            //   "No Network",
            //   "Kindly check your network connection 😢",
            //   snackPosition: SnackPosition.BOTTOM,
            //   borderWidth: double.infinity,
            //   snackStyle: SnackStyle.GROUNDED,
            //   maxWidth: double.infinity,
            //   backgroundColor: Colors.redAccent,
            //   colorText: Colors.white,
            //   duration: Duration(days: 1), // Persistent duration
            //   isDismissible: false, // Prevent manual dismiss
            //   icon: const Icon(Icons.wifi_off, color: Colors.white),
            //   animationDuration: Duration(seconds: 4),
            //   reverseAnimationCurve: Curves.easeOut,
            //   margin: EdgeInsets.zero,
            // );
          }
        });
      }
    } else {
      isConnected.value = true;
      if (Get.isSnackbarOpen) {
        Get.closeAllSnackbars(); // Close snackbar when network is back
      }
    }
  }

  @override
  void onInit() {
   
    print("start dashboard");
    checkForUpdate();
    
    // Initialize connectivity listener
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
    
    // Initial connectivity check
    _checkInitialConnectivity();

    super.onInit();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      print("Initial connectivity check: $results -> isConnected: ${isConnected.value}");
    } catch (e) {
      print("Error checking initial connectivity: $e");
      isConnected.value = false;
    }
  }

  Future<void> refreshConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _updateConnectionStatus(results);
      print("Manual connectivity refresh: $results -> isConnected: ${isConnected.value}");
    } catch (e) {
      print("Error refreshing connectivity: $e");
      isConnected.value = false;
    }
  }
}
