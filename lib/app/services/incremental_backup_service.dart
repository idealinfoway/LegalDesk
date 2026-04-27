import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';

// ---------------------------------------------------------------------------
// Manifest entry
// ---------------------------------------------------------------------------

class _ManifestEntry {
  final String fileName;
  final String md5;
  final int modifiedMs;
  final String? driveFileId;

  _ManifestEntry({
    required this.fileName,
    required this.md5,
    required this.modifiedMs,
    this.driveFileId,
  });

  factory _ManifestEntry.fromJson(Map<String, dynamic> j) => _ManifestEntry(
        fileName: (j['fileName'] ?? '').toString(),
        md5: (j['md5'] ?? '').toString(),
        modifiedMs: _parseModifiedMs(j['modifiedMs']),
        driveFileId: (j['driveFileId']?.toString().isNotEmpty ?? false)
            ? j['driveFileId'].toString()
            : null,
      );

  static int _parseModifiedMs(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw) ?? 0;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'md5': md5,
        'modifiedMs': modifiedMs,
        if (driveFileId != null) 'driveFileId': driveFileId,
      };
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Incremental file-level backup to Google Drive.
///
/// Drive layout
/// ────────────
///   legaldesk_backup/          ← folder (created on first backup)
///   ├── manifest.json          ← index: filename → {md5, driveFileId, ...}
///   ├── clients.hive
///   ├── cases.hive
///   └── ... (.hive / .pdf / .doc / .docx / .txt / .jpg / .jpeg / .png)
///
/// Migration
/// ─────────
/// If the old single-zip backup (legaldesk_backup.zip) is found on Drive,
/// it is extracted and its files are uploaded individually into the new
/// folder layout, then the zip is deleted. This runs once automatically.
class IncrementalBackupService {
  IncrementalBackupService._();
  static final instance = IncrementalBackupService._();

  final _lock = Lock();

  static const driveFolderName = 'legaldesk_backup';
  static const legacyZipName   = 'legaldesk_backup.zip'; // old format
  static const manifestFileName = 'manifest.json';

  static const _backupExtensions = {
    '.hive',
    '.pdf',
    '.doc',
    '.docx',
    '.txt',
    '.jpg',
    '.jpeg',
    '.png',
  };

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Backs up only changed / new files.
  ///
  /// IMPORTANT: caller must flush + close Hive boxes BEFORE calling this so
  /// the .hive files on disk are complete and consistent.
  ///
  /// Returns {uploaded: N, skipped: M, totalFiles: T}.
  Future<Map<String, int>> backupToDrive(drive.DriveApi driveApi) {
    return _lock.synchronized(() => _backup(driveApi));
  }

  /// Restores files from Drive to the local app directory.
  ///
  /// Always downloads every file in the remote manifest (forceDownloadAll
  /// semantics are always on for login restore — there is no safe way to
  /// trust the local manifest after a sign-out or reinstall).
  ///
  /// [onBeforeRestore] is called right before files are written — use it to
  /// close Hive boxes so their files can be safely overwritten.
  Future<void> restoreFromDrive(
    drive.DriveApi driveApi, {
    Future<void> Function()? onBeforeRestore,
  }) {
    return _lock.synchronized(
      () => _restore(driveApi, onBeforeRestore: onBeforeRestore),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Backup
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, int>> _backup(drive.DriveApi driveApi) async {
    final appPath = (await getApplicationDocumentsDirectory()).path;

    // Collect the files that exist on disk right now.
    final localFiles = await _collectBackupFiles(appPath);
    if (localFiles.isEmpty) {
      return {'uploaded': 0, 'skipped': 0, 'totalFiles': 0};
    }

    // Ensure the Drive folder exists.
    final folderId = await _ensureDriveFolder(driveApi);

    // Load the remote manifest — this is the authoritative record of what
    // is already on Drive with which file IDs.
    final remoteManifest = await _loadRemoteManifest(driveApi, folderId);

    // Load the local manifest — records what we uploaded last time FROM this
    // device. Used only to skip files whose content hasn't changed.
    final localManifest = await _loadLocalManifest(appPath);

    // Working copy: start from remote so we inherit all driveFileIds.
    final manifest = Map<String, _ManifestEntry>.from(remoteManifest);

    int uploaded = 0;
    int skipped  = 0;

    for (final file in localFiles) {
      final name  = _canonicalLocalName(file.path);
      if (name.isEmpty) continue;
      final bytes = await file.readAsBytes();
      final currentMd5 = _md5Hex(bytes);

      // Skip if local manifest confirms this exact content is already on Drive.
      final localPrev  = localManifest[name];
      final remotePrev = remoteManifest[name];
      if (localPrev != null &&
          localPrev.md5 == currentMd5 &&
          remotePrev?.driveFileId != null) {
        skipped++;
        continue;
      }

      final driveId = await _uploadFile(
        driveApi,
        folderId: folderId,
        fileName: name,
        bytes: bytes,
        existingFileId: remotePrev?.driveFileId,
      );

      manifest[name] = _ManifestEntry(
        fileName: name,
        md5: currentMd5,
        modifiedMs: (await file.lastModified()).millisecondsSinceEpoch,
        driveFileId: driveId,
      );
      uploaded++;
    }

    // Persist manifest both locally and on Drive.
    await _saveManifestLocally(appPath, manifest);
    await _uploadManifest(driveApi, folderId, manifest);

    return {
      'uploaded': uploaded,
      'skipped': skipped,
      'totalFiles': localFiles.length,
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Restore
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _restore(
    drive.DriveApi driveApi, {
    Future<void> Function()? onBeforeRestore,
  }) async {
    final appPath = (await getApplicationDocumentsDirectory()).path;

    // ── Step 1: migrate legacy ZIP if present ─────────────────────────────
    final migrated = await _migrateLegacyZipIfNeeded(driveApi, appPath,
        onBeforeRestore: onBeforeRestore);
    if (migrated) return; // migration handled everything, including box-close

    // ── Step 2: find the new-format folder ────────────────────────────────
    final folderId = await _findDriveFolder(driveApi);
    if (folderId == null) throw const _NoBackupException();

    // ── Step 3: load remote manifest ─────────────────────────────────────
    final remoteManifest = await _loadRemoteManifest(driveApi, folderId);
    if (remoteManifest.isEmpty) throw const _NoBackupException();

    // ── Step 4: always download everything ───────────────────────────────
    // We do NOT trust the local manifest here. After sign-out, Hive files
    // are cleared; after a reinstall the manifest.json may not exist at all.
    // Downloading all files is the only safe option for login-time restore.
    final toDownload = remoteManifest.values
        .where((e) => e.driveFileId != null)
        .toList();

    if (toDownload.isEmpty) throw const _NoBackupException();

    // ── Step 5: close boxes, then write files ────────────────────────────
    if (onBeforeRestore != null) await onBeforeRestore();

    for (final entry in toDownload) {
      final fileName = _canonicalLocalName(entry.fileName);
      if (fileName.isEmpty) continue;
      final bytes = await _downloadFile(driveApi, entry.driveFileId!);
      final outFile = File(p.join(appPath, fileName));
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(bytes, flush: true);
    }

    // ── Step 6: sync local manifest ───────────────────────────────────────
    await _saveManifestLocally(appPath, remoteManifest);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Legacy ZIP migration
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true if a legacy ZIP was found and migrated.
  Future<bool> _migrateLegacyZipIfNeeded(
    drive.DriveApi driveApi,
    String appPath, {
    Future<void> Function()? onBeforeRestore,
  }) async {
    // Look for the old single-file ZIP on Drive.
    final zipResult = await driveApi.files.list(
      q: "name='$legacyZipName' and trashed=false",
      spaces: 'drive',
      $fields: 'files(id,name)',
    );
    final zipFile = zipResult.files?.firstOrNull;
    if (zipFile == null) return false; // no legacy backup — nothing to migrate

    print('[Backup] Found legacy ZIP — migrating to new format...');

    // Download the ZIP.
    final zipBytes = await _downloadFile(driveApi, zipFile.id!);

    // Close Hive boxes before writing files.
    if (onBeforeRestore != null) await onBeforeRestore();

    // Extract ZIP entries directly into the app documents directory.
    final archive = ZipDecoder().decodeBytes(zipBytes);
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final fileName = _canonicalLocalName(entry.name);
      if (fileName.isEmpty) continue;
      final ext = _extensionOf(fileName);
      if (!_backupExtensions.contains(ext)) continue;

      final outFile = File(p.join(appPath, fileName));
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(entry.content as List<int>, flush: true);
    }

    print('[Backup] Legacy ZIP extracted. Now uploading to new folder format...');

    // Re-collect the now-restored local files and back them up in the new format.
    // This creates the folder + manifest on Drive automatically.
    // We deliberately do NOT pass onBeforeRestore again — boxes were already closed.
    await _backup(driveApi);

    // Delete the legacy ZIP so we don't migrate again next time.
    try {
      await driveApi.files.delete(zipFile.id!);
      print('[Backup] Legacy ZIP deleted from Drive.');
    } catch (e) {
      print('[Backup] Could not delete legacy ZIP (non-fatal): $e');
    }

    print('[Backup] Migration complete.');
    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Drive folder helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> _ensureDriveFolder(drive.DriveApi driveApi) async {
    final existing = await _findDriveFolder(driveApi);
    if (existing != null) return existing;
    final folder = drive.File()
      ..name = driveFolderName
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await driveApi.files.create(folder, $fields: 'id');
    return created.id!;
  }

  Future<String?> _findDriveFolder(drive.DriveApi driveApi) async {
    final result = await driveApi.files.list(
      q: "name='$driveFolderName'"
          " and mimeType='application/vnd.google-apps.folder'"
          " and trashed=false",
      spaces: 'drive',
      $fields: 'files(id)',
    );
    return result.files?.firstOrNull?.id;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Upload / download helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> _uploadFile(
    drive.DriveApi driveApi, {
    required String folderId,
    required String fileName,
    required Uint8List bytes,
    String? existingFileId,
  }) async {
    Future<String> createNew() async {
      final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);
      final meta  = drive.File()
        ..name    = fileName
        ..parents = [folderId];
      final created = await driveApi.files.create(meta,
          uploadMedia: media, $fields: 'id');
      return created.id!;
    }

    if (existingFileId == null) return createNew();

    try {
      final media = drive.Media(Stream.fromIterable([bytes]), bytes.length);
      final updated = await driveApi.files.update(
        drive.File(),
        existingFileId,
        uploadMedia: media,
        $fields: 'id',
      );
      return updated.id!;
    } on drive.DetailedApiRequestError catch (e) {
      // File was deleted externally — create fresh.
      if (e.status == 404) return createNew();
      rethrow;
    }
  }

  Future<Uint8List> _downloadFile(
      drive.DriveApi driveApi, String fileId) async {
    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;
    final chunks = <int>[];
    await for (final chunk in media.stream) {
      chunks.addAll(chunk);
    }
    return Uint8List.fromList(chunks);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Manifest helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _uploadManifest(
    drive.DriveApi driveApi,
    String folderId,
    Map<String, _ManifestEntry> manifest, {
    String? existingId,
  }) async {
    // If we weren't given an existing ID, look it up.
    String? resolvedId = existingId;
    if (resolvedId == null) {
      final result = await driveApi.files.list(
        q: "name='$manifestFileName' and '$folderId' in parents and trashed=false",
        $fields: 'files(id)',
      );
      resolvedId = result.files?.firstOrNull?.id;
    }

    final bytes = Uint8List.fromList(
      utf8.encode(jsonEncode(manifest.map((k, v) => MapEntry(k, v.toJson())))),
    );
    await _uploadFile(
      driveApi,
      folderId: folderId,
      fileName: manifestFileName,
      bytes: bytes,
      existingFileId: resolvedId,
    );
  }

  Future<Map<String, _ManifestEntry>> _loadRemoteManifest(
    drive.DriveApi driveApi,
    String folderId,
  ) async {
    try {
      final result = await driveApi.files.list(
        q: "name='$manifestFileName' and '$folderId' in parents and trashed=false",
        $fields: 'files(id)',
      );
      final fileId = result.files?.firstOrNull?.id;
      if (fileId == null) return {};
      final bytes   = await _downloadFile(driveApi, fileId);
      final jsonMap = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

      final parsed = <String, _ManifestEntry>{};
      for (final row in jsonMap.entries) {
        final value = row.value;
        if (value is! Map) continue;

        final payload = Map<String, dynamic>.from(value);
        payload.putIfAbsent('fileName', () => row.key);

        final entry = _ManifestEntry.fromJson(payload);
        parsed[row.key] = entry;
      }

      return _normalizeManifest(parsed);
    } catch (e) {
      print('[Backup] Could not load remote manifest (treating as empty): $e');
      return {};
    }
  }

  Future<Map<String, _ManifestEntry>> _loadLocalManifest(
      String appPath) async {
    final file = File('$appPath/$manifestFileName');
    if (!await file.exists()) return {};
    try {
      final jsonMap =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;

      final parsed = <String, _ManifestEntry>{};
      for (final row in jsonMap.entries) {
        final value = row.value;
        if (value is! Map) continue;

        final payload = Map<String, dynamic>.from(value);
        payload.putIfAbsent('fileName', () => row.key);

        final entry = _ManifestEntry.fromJson(payload);
        parsed[row.key] = entry;
      }

      return _normalizeManifest(parsed);
    } catch (e) {
      print('[Backup] Could not parse local manifest (treating as empty): $e');
      return {};
    }
  }

  Future<void> _saveManifestLocally(
    String appPath,
    Map<String, _ManifestEntry> manifest,
  ) async {
    await File('$appPath/$manifestFileName').writeAsString(
      jsonEncode(manifest.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // File collection
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<File>> _collectBackupFiles(String appPath) async {
    final files = <File>[];
    await for (final entity in Directory(appPath).list()) {
      if (entity is! File) continue;
      if (_backupExtensions.contains(_extensionOf(entity.path))) {
        files.add(entity);
      }
    }
    return files;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Utilities
  // ─────────────────────────────────────────────────────────────────────────

  String _md5Hex(Uint8List bytes) => md5.convert(bytes).toString();

  String _canonicalLocalName(String rawPathOrName) {
    final normalized = rawPathOrName.trim().replaceAll('\\', '/');
    if (normalized.isEmpty) return '';
    return p.basename(normalized);
  }

  Map<String, _ManifestEntry> _normalizeManifest(
    Map<String, _ManifestEntry> input,
  ) {
    final normalized = <String, _ManifestEntry>{};

    for (final row in input.entries) {
      final rawName = row.value.fileName.isNotEmpty
          ? row.value.fileName
          : row.key;
      final fileName = _canonicalLocalName(rawName);
      if (fileName.isEmpty) continue;

      final candidate = _ManifestEntry(
        fileName: fileName,
        md5: row.value.md5,
        modifiedMs: row.value.modifiedMs,
        driveFileId: row.value.driveFileId,
      );

      final existing = normalized[fileName];
      if (existing == null || candidate.modifiedMs >= existing.modifiedMs) {
        normalized[fileName] = candidate;
      }
    }

    return normalized;
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    return dot >= 0 ? path.substring(dot).toLowerCase() : '';
  }
}

class _NoBackupException implements Exception {
  const _NoBackupException();
  @override
  String toString() => 'No backup found on Google Drive.';
}