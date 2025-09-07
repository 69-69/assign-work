import 'dart:io';
import 'dart:typed_data';

import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/*USAGE:
* ({Uint8List logo, String bg}) img = await LoadPrintAsset.loadImg();
  pw.SvgImage(svg: img.bg);
* */
class LoadPrintoutAsset {
  /// Save PDF Printout to device directory [savePdf]
  Future<File> savePdf(pdf) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/print-doc-setup.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Load local asset images [loadImg]
  static Future<({Uint8List? logo, String bg})> loadImg({
    String? companyLogo,
    String? replaceSvgColorHex,
  }) async {
    // Printout Company logo
    Uint8List? logo;

    if (companyLogo != null && companyLogo.isNotEmpty) {
      logo = await rootBundle
          .load(companyLogo)
          .then((data) => data.buffer.asUint8List());
    }

    // Printout Footer Background Image
    var footerBg = await rootBundle.loadString(printFooterBg);

    if (!replaceSvgColorHex.isNullOrEmpty) {
      // Modify SVG content to change background color
      footerBg = footerBg.replaceFirst(
        '<path id="path24" style="fill:#0c92d6;',
        '<path id="path24" style="fill:$replaceSvgColorHex;',
      );
    }

    return (logo: logo, bg: footerBg);
  }
}
