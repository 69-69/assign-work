import 'dart:io';

import 'package:assign_erp/core/network/data_sources/models/result_data.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/widgets/files/file_doc_manager.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/backup_filenames_cache.dart';

class DataBackupManager {
  /// Delete files in a directory [deleteCache]
  /* USAGE:
  * final directory = Directory('/path/to/directory');
  * await DataBackupManager.deleteCache(
  *   directory: directory,
  *   skipFileNames: {
  *     'file1.txt',
  *     'file2.txt',},
  *   recursive: true,
  * });
  * */
  static Future<Result<String>> deleteCache({
    Directory? directory,
    Set<String> skipFileNames = const {},
    bool recursive = false,
  }) async {
    final dir = directory ?? (await FileDocManager.getLocalBackupDir()).dirObj;

    return await FileDocManager.deleteFilesInDirectory(directory: dir);
  }

  static Future<Result<String>> startBackup({
    required String zipFileName,
    bool isLocal = true,
  }) async {
    final data = zipFileName.generateBackupFileName;
    final newZipFilename = '${data.filename}.zip';

    final zipResult = await FileDocManager.zipFolder(
      zipFileName: newZipFilename,
    );

    if (zipResult is Success<File>) {
      final zipFile = zipResult.data;

      BackupFilenameCache().setBackupFilename({
        'id': data.id,
        'filename': newZipFilename,
      });

      if (!isLocal) {
        await FileDocManager.saveZipFileToUserLocation(zipFile: zipFile);
      }
      return Success(data: 'Backup completed: $zipFile');
    }
    return Failure(message: 'Backup failed');
  }

  /// Restore from Local/External ZIP file (stored locally or drive storage)
  static Future<Result<String>> startRestore({
    required String zipFileName,
    required isLocal,
  }) async {
    if (!isLocal) {
      return await _handleRestoreFromDrive();
    }

    return await _handleRestoreFromLocal(zipFileName);
  }

  /// Restore from Local/Internal ZIP file (stored locally)
  static Future<Result<String>> _handleRestoreFromLocal(
    String zipFileName,
  ) async {
    final unzipResult = await _unzipAndReport(zipFileName: zipFileName);
    return unzipResult;
  }

  /// Restore from External (user-picked) ZIP file
  static Future<Result<String>> _handleRestoreFromDrive({
    String? zipFileName,
  }) async {
    final pickedFile = await FileDocManager.pickZipFileFromUserLocation();
    if (pickedFile is! Success<File>) {
      return Failure(message: 'No ZIP file selected or failed to pick.');
    }

    final fullPathToFile = pickedFile.data.path;
    final filename = zipFileName ?? FileDocManager.getFileName(fullPathToFile);

    final unzipResult = await _unzipAndReport(
      zipFileName: filename,
      zipFilePath: fullPathToFile,
    );

    return unzipResult;
  }

  static Future<Result<String>> _unzipAndReport({
    required String zipFileName,
    String? zipFilePath,
  }) async {
    final unzipResult = await FileDocManager.unzipFile(
      zipFileName: zipFileName,
      zipFilePath: zipFilePath,
    );

    if (unzipResult is Success<String>) {
      return Success(data: 'Restore completed: [PATH]: ${unzipResult.data}');
    }

    return Failure(message: 'Restore failed during unzip.');
  }
}

/* ✅ Step 1: Zip a Folder
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<File> zipFolder({
  required Directory inputDir,
  required String zipFileName,
}) async {
  final archive = Archive();

  for (final entity in inputDir.listSync(recursive: true)) {
    if (entity is File) {
      final relativePath = p.relative(entity.path, from: inputDir.path);
      final bytes = entity.readAsBytesSync();
      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
    }
  }

  final zipData = ZipEncoder().encode(archive);
  final outputDir = await getTemporaryDirectory();
  final zipFile = File(p.join(outputDir.path, zipFileName));
  await zipFile.writeAsBytes(zipData!);

  return zipFile;
}

* ✅ Step 2: Save or Share the File
import 'package:file_picker/file_picker.dart';

Future<void> saveZipToUserLocation(File zipFile) async {
    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ZIP File',
        fileName: p.basename(zipFile.path),
      );

      if (savePath != null && savePath.isNotEmpty) {
        await zipFile.copy(savePath);
        debugPrint('ZIP file saved to $savePath');
      } else {
        debugPrint('No file selected for saving.');
      }
    } catch (e) {
      debugPrint('Error saving file: $e');
    }
  }

* Without using package:file_picker
Future<void> saveZipToUserLocation(File zipFile) async {
    try {
      // Get the app's documents directory (Android/iOS)
      final appDocDir = await getApplicationDocumentsDirectory();
      final savePath = p.join(appDocDir.path, p.basename(zipFile.path));

      // Copy the file to the documents directory
      await zipFile.copy(savePath);

      print('ZIP file saved to $savePath');
    } catch (e) {
      print('Failed to save ZIP file: $e');
    }
  }

🔹 Option 2: Share the ZIP file (Mobile)
import 'package:share_plus/share_plus.dart';

void shareZipFile(File zipFile) {
  Share.shareXFiles([XFile(zipFile.path)], text: 'Here is your zipped file');
}

* ✅ Web ZIP + Download
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:archive/archive.dart';

void createAndDownloadZipOnWeb() {
  final archive = Archive();

  // Example content
  archive.addFile(ArchiveFile('hello.txt', 5, utf8.encode('Hello')));
  archive.addFile(ArchiveFile('folder/greet.txt', 7, utf8.encode('Welcome')));

  final zipData = ZipEncoder().encode(archive)!;
  final blob = html.Blob([Uint8List.fromList(zipData)]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", "my_archive.zip")
    ..click();

  html.Url.revokeObjectUrl(url);
}

*/
