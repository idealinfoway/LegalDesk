import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    print('SplashView: Building splash screen');
    print('SplashView: Controller is ${controller != null ? 'available' : 'null'}');
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
                width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              // App Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.gavel,
                  size: 60,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 40),
              // App Title
              Text(
                'LegalDesk',
                style: TextStyle(
                  fontFamily: 'poppins',
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              // Subtitle
              Text(
                'Your Legal Case Manager',
                style: TextStyle(
                  fontFamily: 'poppins',
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 60),
              // Loading Animation
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                ),
              ),
              const SizedBox(height: 24),
              // Loading Text
              Text(
                'Loading...',
                style: TextStyle(
                  fontFamily: 'poppins',
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
