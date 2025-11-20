import 'dart:io';

import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/local/setup_printout_model.dart';
import 'package:assign_erp/core/util/debug_printify.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/async_progress_dialog.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

String getFileExtension(String filePath) {
  // Find the last occurrence of '.' in the file path
  int dotIndex = filePath.lastIndexOf('.');

  // If a '.' was found and it's not at the end of the string
  if (dotIndex != -1 && dotIndex < filePath.length - 1) {
    // Return the substring from the dot index + 1 to the end of the string
    return filePath.substring(dotIndex + 1);
  } else {
    // If no extension is found, return an empty string or handle as needed
    return '';
  }
}

class UploadCompanyLogo extends StatefulWidget {
  const UploadCompanyLogo({
    super.key,
    this.serverFilePath,
    this.uploadedFilePath,
  });

  final Function(String)? uploadedFilePath;
  final String? serverFilePath;

  @override
  State<UploadCompanyLogo> createState() => _UploadCompanyLogoState();
}

class _UploadCompanyLogoState extends State<UploadCompanyLogo> {
  final SetupPrintOut _setupPrintOut = SetupPrintOut();
  final PrintoutSetupCacheService _printoutService =
      PrintoutSetupCacheService();

  final List<String> _imgType = ['png, jpg, jpeg'];

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    if ((_imageFile == null) && !widget.serverFilePath.isNullOrEmpty) {
      _imageFile = File(widget.serverFilePath!);
    }
  }

  Future<void> _pickAndSaveImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      final imgFile = File(pickedFile.path);

      final image = await decodeImageFromList(imgFile.readAsBytesSync());
      final fileExtension = getFileExtension(pickedFile.path);

      if (!_imgType.any((a) => a.contains(fileExtension))) {
        if (mounted) {
          context.showImgExtensionWarningDialog();
        }
      } else if (image.width > 300 || image.height > 320) {
        if (mounted) {
          context.showImgSizeWarningDialog();
        }
      } else {
        setState(() => _imageFile = imgFile);

        await _savingImgStarted(pickedFile);
      }
    }
  }

  // Save file to Device Directory
  Future<void> _saveImageToDirectory(XFile pickedImg) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String appDocPath = appDocDir.path;
      // final String path = '$appDocPath/${DateTime.now().millisecondsSinceEpoch}_${image.name}';

      // Get the file extension
      final fileExtension = getFileExtension(pickedImg.path);
      final String imgPath =
          '$appDocPath/assign_360_client_logo.$fileExtension';

      _imageFile = File(imgPath);

      // save image
      // await imageFile.writeAsBytes(await image.readAsBytes());
      await pickedImg.saveTo(_imageFile!.path);

      // Update UI
      setState(() => widget.uploadedFilePath!(imgPath));

      // Save to Cache
      // _saveToCache(imgPath);

      // debugPrint('Image saved to $fileExtension');
    } catch (e) {
      // debugPrint('Error saving image: $e');
    }
  }

  Future<void> _savingImgStarted(XFile pickedImg) async {
    // Show progress dialog while deleting data
    await context.progressBarDialog(
      request: Future.delayed(
        kRProgressDelay,
        () async => await _saveImageToDirectory(pickedImg),
      ),
      onSuccess: (_) => context.showAlertOverlay('Logo successfully saved'),
      onError: (error) =>
          context.showAlertOverlay('Logo saving failed', bgColor: kDangerColor),
    );
  }

  // Delete file from Device Directory
  Future<void> _deleteImage() async {
    if (_imageFile != null) {
      prettyPrint('deleteImage', 'Error saving image: ...');
      try {
        if (await _imageFile!.exists()) {
          await _imageFile!.delete();

          await _deleteFromCache();

          setState(() => _imageFile = null);

          // Update UI
          setState(() => widget.uploadedFilePath!(''));

          if (mounted) {
            context.showAlertOverlay('Image deleted');
          }
        }
      } catch (e) {
        // debugPrint('Error saving image: $e');
        if (mounted) {
          context.showAlertOverlay('Error deleting image');
        }
      }
    }
  }

  // Delete filePath from cache
  Future<void> _deleteFromCache() async {
    final settings = _setupPrintOut.copyWith(companyLogo: null);
    if (settings.isNotEmpty) {
      await _printoutService.setSettings(settings);
    }
  }

  Future<void> _deleteImgStarted() async {
    // Show progress dialog while deleting data
    await context.progressBarDialog(
      request: Future.delayed(
        kRProgressDelay,
        () async => await _deleteImage(),
      ),
      onSuccess: (_) => context.showAlertOverlay('Logo successfully deleted'),
      onError: (error) => context.showAlertOverlay(
        'Logo deleting failed',
        bgColor: kDangerColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        (_imageFile != null)
            ? _buildPreviewImage(_imageFile)
            : const Text('Upload company logo'),
        const SizedBox(height: 20),
        _buildUploadBtn(),
      ],
    );
  }

  _buildPreviewImage(File? imgFile) {
    return !imgFile!.existsSync()
        ? const SizedBox.shrink()
        : Card(
            elevation: 5,
            color: kWhiteColor,
            child: Container(
              width: 200,
              height: 200,
              padding: EdgeInsets.zero,
              margin: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: FileImage(imgFile, scale: 5),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(child: _buildDeleteBtn()),
            ),
          );
  }

  _buildDeleteBtn() {
    return ClipRect(
      child: IconButton(
        tooltip: 'Delete Logo',
        style: IconButton.styleFrom(
          elevation: 30,
          backgroundColor: kDangerColor.toAlpha(0.5),
        ),
        onPressed: _deleteImgStarted,
        icon: const Icon(Icons.close, color: kWhiteColor),
      ),
    );
  }

  _buildUploadBtn() {
    return context.elevatedIconBtn(
      Icon(Icons.image),
      onPressed: _pickAndSaveImage,
      label: const Text('Upload Logo'),
    );
  }
}
