import 'dart:io';

import 'package:archive/archive.dart';
import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/network/data_sources/models/result_data.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CellValue {
  final String? value;

  // Constructor that accepts a nullable value
  CellValue(this.value);
}

class FileDocManager {
  /// File exist in local directory [fileExist]
  static bool fileExist(i) => File(i).existsSync();

  /// Get the file name from the path [getFileName]
  static String getFileName(String filePath) {
    final fileName = p.basename(filePath);
    return fileName;
  }

  /// Get the app directory path [getAppDir]
  static Future getAppDir() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Get the temporary directory [getTemporaryDirectory]
  static Future<Directory> getTemporaryDir() async {
    final directory = await getTemporaryDirectory();
    return directory;
  }

  /// Get the local backup directory [getLocalBackupDir]
  /// This is the where Flutter HiveBox stores local backup files
  static Future<({String dirPath, Directory dirObj})>
  getLocalBackupDir() async {
    final appDir = await getAppDir();
    final backupDirPath = '$appDir/$appCacheDirectory';
    final backupDirObject = Directory(backupDirPath);

    // Create the directory if it does not exist
    if (!await backupDirObject.exists()) {
      await backupDirObject.create(recursive: true);
    }

    return (dirPath: backupDirPath, dirObj: backupDirObject);
  }

  /// // Compress or zip files in the local backup directory into a ZIP file [zipFolder]
  static Future<Result<File>> zipFolder({
    required String zipFileName,
    Set<String> skipFileNames = const {},
  }) async {
    final archive = Archive();
    // Source directory for the zip
    final inputDir = (await getLocalBackupDir()).dirObj;

    // Define filenames to skip while zipping(backup)
    final skipFiles = {
      '$userAuthCache.hive',
      '$userAuthCache.lock',
      '$deviceInfoCache.hive',
      '$deviceInfoCache.lock',
      '$rolesDBCollectionPath.hive',
      '$rolesDBCollectionPath.lock',
      '$workspaceAccDBCollectionPath.hive',
      '$workspaceAccDBCollectionPath.lock',
      '$subscriptionDBCollectionPath.hive',
      '$subscriptionDBCollectionPath.lock',
      ...skipFileNames,
    };

    // Add all files in the directory to the archive
    for (final entity in inputDir.listSync(recursive: true)) {
      if (entity is File) {
        final fileName = p.basename(entity.path);

        // Skip auth cache files
        if (skipFiles.contains(fileName)) {
          continue;
        }

        final relativePath = p.relative(entity.path, from: inputDir.path);
        final bytes = entity.readAsBytesSync();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      }
    }

    // If no files are added, handle it
    if (archive.isEmpty) {
      Failure(message: 'No files to zip in the directory');
    }

    // Encode the archive data to a zip format
    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      return Failure(message: 'Failed to encode zip data');
    }

    // Output directory for the zip file
    final outputDir = (await getTemporaryDir()).path;
    prettyPrint('temp-outputDir', outputDir);

    final zipFile = File(p.join(outputDir, zipFileName));

    // Write the zip data to the file
    await zipFile.writeAsBytes(zipData);

    return Success(data: zipFile);
  }

  /// Unzip/extract the contents of the file to a specific directory [unzipFile]
  static Future<Result<String>> unzipFile({
    required String zipFileName,
    String? zipFilePath,
    String? outputToDir,
  }) async {
    try {
      // Step 1: Determine ZIP file path
      final zipFile = zipFilePath != null
          ? File(zipFilePath)
          : File(p.join((await getTemporaryDir()).path, zipFileName));

      if (!await zipFile.exists()) {
        return Failure(message: 'ZIP file not found: ${zipFile.path}');
      }

      // Step 2: Determine output directory
      final outputDir = outputToDir ?? (await getLocalBackupDir()).dirObj.path;

      // Step 3: Decode ZIP
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final file in archive) {
        if (file.name.trim().isEmpty) continue;

        final filePath = p.join(outputDir, file.name);
        if (file.isFile) {
          final outputFile = File(filePath);
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }

        prettyPrint('Extracted to', filePath);
      }

      return Success(data: outputDir);
    } catch (e) {
      return Failure(message: 'Failed to unzip the file: $e');
    }
  }

  /// Save the ZIP file to the documents directory [saveZipFileToUserLocation]
  static Future<void> saveZipFileToUserLocation({
    required File zipFile,
    String? title,
  }) async {
    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: title ?? 'Save UNZIP File',
        fileName: p.basename(zipFile.path),
      );

      if (savePath != null && savePath.isNotEmpty) {
        await zipFile.copy(savePath);
        prettyPrint('UNZIP file saved to', savePath);
      } else {
        prettyPrint('No file selected for saving', 'Error');
      }
    } catch (e) {
      prettyPrint('Error saving file', '$e');
    }
  }

  /// Picker zip file from external storage [pickZipFileFromUserLocation]
  /// With package:file_picker
  static Future<Result<File>> pickZipFileFromUserLocation() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result == null || result.files.isEmpty) {
        prettyPrint('No file selected for saving', 'Error');
        return Failure(message: 'No file selected for saving.');
      }
      final file = File(result.files.single.path!);
      return Success(data: file);
    } catch (e) {
      prettyPrint('Error picking file', '$e');
      return Failure(message: 'Error picking file: $e');
    }
  }

  /// Single delete file [deleteFile]
  /* USAGE:
  * final filePath = '/path/to/file.txt';
  * final result = await DataBackupManager.deleteFile(filePath: filePath);
  * result.when(
  *   success: (data) => prettyPrint(data),
  *   failure: (message) => prettyPrint(message),
  * );
  * */
  static Future<Result<String>> deleteFile({required String filePath}) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return Failure(message: 'File does not exist: $filePath');
    }
    try {
      await file.delete();
      prettyPrint('File deleted', filePath);
      return Success(data: 'File deleted');
    } catch (e) {
      prettyPrint('Failed to delete $filePath', '$e');
      return Failure(message: 'Failed to delete');
    }
  }

  /// Delete files in a directory [deleteFilesInDirectory]
  /* USAGE:
  * final directory = Directory('/path/to/directory');
  * await DataBackupManager.deleteFilesInDirectory(
  *   directory: directory,
  *   skipFileNames: {
  *     'file1.txt',
  *     'file2.txt',},
  *   recursive: true,
  * });
  * */
  static Future<Result<String>> deleteFilesInDirectory({
    required Directory directory,
    Set<String> skipFileNames = const {},
    bool recursive = false,
  }) async {
    if (!await directory.exists()) {
      return Failure(message: 'Directory does not exist: ${directory.path}');
    }

    final files = directory.listSync(recursive: recursive);

    for (final entity in files) {
      if (entity is File) {
        final fileName = p.basename(entity.path);

        // Skip specific files if needed
        if (skipFileNames.contains(fileName)) {
          continue;
        }

        try {
          if (fileExist(entity)) {
            await entity.delete();
            prettyPrint('File deleted', entity.path);
            return Success(data: 'File deleted');
          }
          return Failure(message: 'File not found: Failed to delete');
        } catch (e) {
          prettyPrint('Failed to delete ${entity.path}', '$e');
          return Failure(message: 'Failed to delete');
        }
      }
    }
    return Failure(message: 'Failed to delete files in directory');
  }

  /// Export data to excel file
  static Future<void> exportDataToExcel({
    List<String>? headers,
    List<List<String>>? data,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['mySheet'];

      // Add headers
      if (headers != null) {
        final headerRow = headers.map((e) => TextCellValue(e)).toList();
        sheet.appendRow(headerRow);
      }

      // Add data
      if (data != null) {
        for (var row in data) {
          final rowCells = row.map((e) => TextCellValue(e)).toList();
          sheet.appendRow(rowCells);
        }
      }

      await saveExcel(excel);
    } catch (e) {
      prettyPrint("Error exporting to Excel", "$e");
    }
  }

  static Future<void> exportDataToPdf({
    required List<String> headers,
    required List<List<String>> data,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.TableHelper.fromTextArray(
            headers: headers,
            data: data,
            cellStyle: const pw.TextStyle(fontSize: 10),
            headerStyle: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
            border: pw.TableBorder.all(color: PdfColors.grey),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
            cellAlignment: pw.Alignment.centerLeft,
          );
        },
      ),
    );

    // You can either share or save
    await savePdf(pdf);
  }

  /// Save binary data to a user-selected location
  static Future<void> saveFileToUserLocation({
    required List<int> bytes,
    required String defaultFileName,
    required String dialogTitle,
    String? successMessage,
    String? errorMessage,
  }) async {
    try {
      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: dialogTitle,
        fileName: defaultFileName,
      );

      if (savePath != null && savePath.isNotEmpty) {
        final file = File(savePath);
        file
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);
        prettyPrint(successMessage ?? 'File saved to', savePath);
      } else {
        prettyPrint('No file selected.', errorMessage ?? 'Error');
      }
    } catch (e) {
      prettyPrint(errorMessage ?? 'Error saving file', '$e');
    }
  }

  /// Save Excel file
  static Future<void> saveExcel(Excel excel) async {
    final bytes = excel.save();

    if (bytes != null) {
      await saveFileToUserLocation(
        bytes: bytes,
        defaultFileName: 'exported_excel_data.xlsx',
        dialogTitle: 'Save Excel File',
      );
    } else {
      prettyPrint('Failed to generate Excel file', 'Error');
    }
  }

  /// Save PDF file
  static Future<void> savePdf(pw.Document pdf) async {
    final bytes = await pdf.save();

    await saveFileToUserLocation(
      bytes: bytes,
      defaultFileName: 'exported_pdf_data.pdf',
      dialogTitle: 'Save PDF File',
    );
  }
}
