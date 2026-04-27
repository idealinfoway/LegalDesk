// import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:hive_flutter/hive_flutter.dart';
import '../../../main.dart';
// import '../login/controller.dart';

class SplashController extends GetxController {

  FirebaseAuth get _auth => FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    _start();
  }

  Future<void> _start() async {
    print('SplashController initialized');

    try {
      await initializeApp(); // ✅ FIRST

      await Future.delayed(const Duration(milliseconds: 800));

      final user = _auth.currentUser; // ✅ SAFE now

      if (user != null) {
        Get.offAllNamed('/dashboard');
      } else {
        Get.offAllNamed('/login');
      }

    } catch (e, stack) {
      print('Startup error: $e');
      print(stack);
      Get.offAllNamed('/login');
    }
  }
}
