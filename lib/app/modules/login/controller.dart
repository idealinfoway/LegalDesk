import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:legalsteward/app/services/incremental_backup_service.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../data/models/user_model.dart';
import '../../services/storage_service.dart';

class LoginController extends GetxController {
  final StorageService _storage = StorageService.instance;

  final GoogleSignIn googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile', 'https://www.googleapis.com/auth/drive.file'],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final RxBool isLoading = false.obs;
  final RxBool isLoggedIn = false.obs;

  /// Path and filename for the backup zip on Google Drive
  // final String driveBackupFileName = 'legaldesk_backup.zip';

  @override
  void onInit() {
    super.onInit();
    // Delay the login check to avoid build conflicts
    Future.delayed(Duration(milliseconds: 100), () {
      checkLoginStatus();
    });
  }

  Future<void> checkLoginStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        isLoggedIn.value = true;
        // Use a microtask to avoid build conflicts
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.offAllNamed('/dashboard');
        });
      }
    } catch (e) {
      // print('Error checking login status: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;

      print('Starting Google Sign-In process...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print('User cancelled Google Sign-In');
        isLoading.value = false;
        return;
      }

      print('Google Sign-In successful for: ${googleUser.email}');

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final authHeaders = await googleUser.authHeaders;
      final client = GoogleAuthClient(authHeaders);

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('Created Firebase credential, signing in...');

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final User? user = userCredential.user;

      if (user != null) {
        print('Firebase authentication successful for: ${user.email}');

        // Save user data to Hive
        await _saveUserToHive(user, googleUser);

        // Restore backup from Drive before navigating to dashboard
        try {
          await restoreFromDrive(client);
        } catch (e) {
          print(
            'No backup found or error restoring from Drive: ${e.toString()}',
          );
        }

        // Ensure all boxes are open before proceeding
        await ensureAllBoxesOpen();

        isLoggedIn.value = true;
        isLoading.value = false;
      } else {
        print('Firebase authentication failed - no user returned');
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'Authentication failed. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      print('Google Sign-In error: $e');
      isLoading.value = false;

      String errorMessage = 'Failed to sign in with Google';
      if (e.toString().contains('network_error')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().contains('sign_in_failed')) {
        errorMessage =
            'Sign-in failed. Please check your Firebase configuration.';
      } else if (e.toString().contains('10:')) {
        errorMessage =
            'Google Sign-In configuration error. Please check your Firebase project settings.';
      } else if (e.toString().contains('PigeonUserDetails')) {
        errorMessage =
            'Google Sign-In version compatibility issue. Please try again.';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: Duration(seconds: 5),
      );
    }
  }

  // Update your _saveUserToHive method
  Future<void> _saveUserToHive(
    User firebaseUser,
    GoogleSignInAccount googleUser,
  ) async {
    try {
      final userBox = await _storage.getBox<UserModel>('user');

      final userModel = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        photoUrl: firebaseUser.photoURL ?? '',
        createdAt: DateTime.now(),
      );

      await userBox.put('current_user', userModel);
      print('User data saved to Hive successfully');
    } catch (e) {
      print('Error saving user to Hive: $e');
    }
  }

  // Update your signOut method
  Future<void> signOut({bool clearCoreData = true}) async {
    try {
      await _auth.signOut();
      await googleSignIn.signOut();

      if (clearCoreData) {
        await _storage.clearCoreBoxes();
      }

      final appDir = await getApplicationDocumentsDirectory();
      final files = appDir.listSync();

      for (var entity in files) {
        if (entity is File &&
            (entity.path.endsWith('.pdf') ||
                entity.path.endsWith('.doc') ||
                entity.path.endsWith('.docx') ||
                entity.path.endsWith('.txt') ||
                entity.path.endsWith('.jpg') ||
                entity.path.endsWith('.jpeg') ||
                entity.path.endsWith('.png'))) {
          try {
            await entity.delete();
          } catch (e) {
            print('Failed to delete PDF: ${entity.path}, Error: $e');
          }
        }
      }

      isLoggedIn.value = false;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.offAllNamed('/login');
      });
    } catch (e) {
      print('Error signing out: $e');
      Get.snackbar(
        'Error',
        'Failed to sign out: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Backup all Hive box files to a zip and upload to Google Drive
  /// Backup all Hive box files to a zip and upload to Google Drive
   // Replace backupToDrive() with this:
  Future<Map<String, int>> backupToDrive(GoogleAuthClient client) async {
  // Close boxes → Hive writes everything to disk → safe to read files.
  await _storage.flushCoreBoxes();
  await Future.delayed(const Duration(milliseconds: 500)); // let OS flush
 
  final driveApi = drive.DriveApi(client);
  final summary = await IncrementalBackupService.instance.backupToDrive(driveApi);
 
  // Re-open boxes so the app keeps working after backup.
  await _storage.ensureCoreBoxesOpen();
 
  return summary;
  // No snackbar here — UI (_handleBackup) owns messaging.
}
 
/// Restores from Drive. Called during sign-in, before navigating to dashboard.
/// Handles both old ZIP format (auto-migrates) and new folder format.
Future<void> restoreFromDrive(GoogleAuthClient client) async {
  try {
    final driveApi = drive.DriveApi(client);
 
    await IncrementalBackupService.instance.restoreFromDrive(
      driveApi,
      onBeforeRestore: () async {
        // Close Hive boxes so their files can be safely overwritten.
        await _storage.closeCoreBoxesSafely();
      },
    );
 
    // Re-open boxes with the freshly restored data.
    await _storage.ensureCoreBoxesOpen();

    // Repair old absolute attachment paths so restored files open correctly.
    final repaired = await _storage.repairAttachmentPathsAfterRestore();
    if (repaired > 0) {
      print('[Backup] Repaired $repaired attachment path(s) after restore.');
    }
  } catch (e) {
    if (e.toString().contains('No backup found')) {
      // First sign-in ever — no backup exists yet. Fine.
      // Make sure boxes are open before continuing.
      await _storage.ensureCoreBoxesOpen();
      return;
    }
    // Re-open boxes even on error so the app doesn't hang.
    await _storage.ensureCoreBoxesOpen();
    rethrow;
  }
}
 
/// Deletes the entire backup folder from Drive (covers new format).
/// Also deletes the legacy ZIP if it still exists.
Future<void> deleteBackupFromDrive(GoogleAuthClient client) async {
  final driveApi = drive.DriveApi(client);
 
  // Delete new-format folder.
  final folderResult = await driveApi.files.list(
    q: "name='${IncrementalBackupService.driveFolderName}'"
        " and mimeType='application/vnd.google-apps.folder'"
        " and trashed=false",
    $fields: 'files(id)',
  );
  final folderId = folderResult.files?.firstOrNull?.id;
  if (folderId != null) await driveApi.files.delete(folderId);
 
  // Also delete legacy ZIP if it's still around.
  final zipResult = await driveApi.files.list(
    q: "name='${IncrementalBackupService.legacyZipName}' and trashed=false",
    $fields: 'files(id)',
  );
  final zipId = zipResult.files?.firstOrNull?.id;
  if (zipId != null) await driveApi.files.delete(zipId);
}
  
  Future<void> ensureAllBoxesOpen() async {
    await _storage.ensureCoreBoxesOpen();
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}
