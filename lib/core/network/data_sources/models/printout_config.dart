import 'dart:typed_data';

import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/load_print_out_asset.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

const String kSignatureLine = '__________________________';

class PrintPDFConfig {
  // final String footerColorStr;
  Uint8List? logo;
  String footerImg;
  final bool isDenseLayout;
  final PdfColor blackColor;
  final PdfColor headerColor;
  final PdfColor footerColor;
  final PdfColor baseTextColor;
  final IssuerCompany company;
  final double bodyFontSize;
  final double headerFontSize;
  final double subHeaderFontSize;
  final double tableFontSize;

  // this.baseColor = PdfColors.teal, // header
  // this.accentColor = PdfColors.blueGrey900, // footer

  PrintPDFConfig._({
    // required this.footerColorStr,
    required this.company,
    required this.logo,
    required this.footerImg,
    required this.isDenseLayout,
    required this.blackColor,
    required this.headerColor,
    required this.footerColor,
    required this.baseTextColor,
    required this.bodyFontSize,
    required this.headerFontSize,
    required this.subHeaderFontSize,
    required this.tableFontSize,
  });

  // Asynchronous factory constructor
  static Future<PrintPDFConfig> create() async {
    final PrintoutSetupCacheService service = PrintoutSetupCacheService();
    var setup = await service.getSettings();

    // Load Printout-Assets Images
    ({String bg, Uint8List? logo}) img = await LoadPrintoutAsset.loadImg(
      companyLogo: setup?.companyLogo,
      replaceSvgColorHex: setup?.footerColor,
    );

    String footerImg = img.bg;
    Uint8List? logo = img.logo;
    IssuerCompany company = IssuerCompany.empty;
    // String footerColorStr = '';
    bool isDenseLayout = true;
    PdfColor blackColor = PdfColors.black;
    PdfColor headerColor = PdfColors.teal;
    PdfColor footerColor = PdfColors.blueGrey900;
    PdfColor baseTextColor = PdfColors.white;
    double bodyFontSize = setup?.bodyFontSize ?? 11.0;
    double tableFontSize = setup?.tableFontSize ?? 10.0;
    double headerFontSize = setup?.headerFontSize ?? 13.0;
    double subHeaderFontSize = setup?.subHeaderFontSize ?? 12.0;

    if (setup != null && !setup.isColorsEmpty) {
      company = IssuerCompany(
        name: (setup.companyName ?? '').toTitle,
        email: setup.companyEmail ?? '',
        phone: setup.companyPhone ?? '',
        fax: setup.companyFax ?? '',
        address: (setup.companyAddress ?? '').toSentence,
      );
      isDenseLayout = setup.layout == 'dense';
      // footerColorStr = setup.headerColor;
      headerColor = PdfColor.fromHex(setup.headerColor);
      footerColor = PdfColor.fromHex(setup.footerColor);
      baseTextColor = headerColor.isLight ? PdfColors.white : blackColor;
    }

    return PrintPDFConfig._(
      // footerColorStr: footerColorStr,
      company: company,
      logo: logo,
      footerImg: footerImg,
      isDenseLayout: isDenseLayout,
      blackColor: blackColor,
      headerColor: headerColor,
      footerColor: footerColor,
      baseTextColor: baseTextColor,
      bodyFontSize: bodyFontSize,
      tableFontSize: tableFontSize,
      headerFontSize: headerFontSize,
      subHeaderFontSize: subHeaderFontSize,
    );
  }
}

/// Company issuing Invoice info [IssuerCompany]
class IssuerCompany {
  const IssuerCompany({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.fax = '',
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String fax;

  /// A singleton instance representing an empty/default IssuerCompany.
  /// Used as a fallback when no matching IssuerCompany is found.
  static final empty = IssuerCompany(
    email: '',
    name: '',
    phone: '',
    address: '',
  );

  /// Returns true if this instance is the singleton [empty] IssuerCompany.
  /// Use this to check if the IssuerCompany is the default/fallback (e.g., not found).
  bool get isEmpty => identical(this, IssuerCompany.empty);
}

/// Print Items Invoice, Proforma, RequestForQuotation, DeliveryNote [PrintItem]
class PrintItem {
  const PrintItem({
    this.currencySign = ghanaCedis,
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
    required this.discount,
    this.taxNames,
    this.taxAmount,
    this.paymentTerms,
    this.deliveryAmt = 0.0,
    this.taxPercent = 0.0,
    this.validityDate,
    this.sku,
  });

  final String? sku;
  final String? currencySign;
  final double discount;
  final String itemName;
  final double unitPrice;
  final double quantity;
  final double? taxAmount;
  final String? taxNames;
  final double deliveryAmt;
  final double taxPercent;
  final String? validityDate;
  final String? paymentTerms;

  // Individual subTotal
  double get _subTotal => unitPrice * quantity;

  // discountPercent / 100 * subTotal
  double get _discountAmt => (discount / 100) * _subTotal;

  /// NetPrice: Is after discount is applied to subTotal [totalNetPrice]
  double get totalNetPrice => _subTotal - _discountAmt + (taxAmount ?? 0.0);

  String getIndex(String label, int index) {
    // final  skuLength = sku != null ? (sku!.length ~/ 2) : 0;
    // sku?.substring(0, skuLength) ?? '';
    var count = index + 1;

    final i = switch (label) {
      'sku#' || '#' || 'no' => count.toString(),
      'item description' || 'item' => itemName,
      'quantity' || 'qty' => quantity.toString(),
      'unit price' || 'price' => formatCurrency(unitPrice, currencySign),
      'discount' => _formatDiscount,
      'tax amount' => formatCurrency(taxAmount, currencySign),
      'tax codes' => taxNames ?? '',
      'net price' ||
      'line total' => formatCurrency(totalNetPrice, currencySign),
      _ => 'NA',
    };
    return i;
  }

  String get _formatDiscount => discount > 0
      ? '$ghanaCedis${_discountAmt.toCurrency} (${discount.toPercent}%)'
      : '';

  static String formatCurrency(double? amt, [String? sign = ghanaCedis]) =>
      amt != null && amt > 0 ? '$sign${amt.toCurrency}' : '';

  // final format = DateFormat.yMEd();
  static String formatDate(DateTime date) =>
      DateFormat.yMMMd('en_US').format(date);
}

/// Print Sales Reports [ReportItem]
class ReportItem {
  const ReportItem({
    required this.salesDate,
    required this.totalSales,
    required this.totalOrders,
    this.totalDiscounts = 0.0,
    this.totalTaxes = 0.0,
    required this.totalItemsSold,
  });

  final double totalDiscounts;
  final String salesDate;
  final double totalSales;
  final int totalOrders;
  final int totalItemsSold;
  final double totalTaxes;

  String getIndex(String label, int index) {
    // final  skuLength = sku != null ? (sku!.length ~/ 2) : 0;
    // sku?.substring(0, skuLength) ?? '';
    var count = index + 1;

    switch (label) {
      case '#':
        return count.toString();
      case 'sales date':
        return salesDate;
      case 'total sales':
        return formatCurrency(totalSales);
      case 'total orders':
        return totalOrders.toString();
      case 'total items sold':
        return totalItemsSold.toString();
      case 'total discounts':
        return totalDiscounts.toString();
      case 'total taxes':
        return totalTaxes.toString();
    }
    return '';
  }

  static String formatCurrency(double amt, {String sign = ghanaCedis}) =>
      amt > 0 ? '$sign${amt.toCurrency}' : '';
}

/// PDF/Printout Font Manager [FontManager]
class FontManager {
  static pw.Font? _base, _bold, _italic;

  static Future<void> loadFonts() async {
    _base ??= await PdfGoogleFonts.robotoRegular();
    _bold ??= await PdfGoogleFonts.robotoBold();
    _italic ??= await PdfGoogleFonts.robotoItalic();
  }

  static pw.Font get base => _base!;
  static pw.Font get bold => _bold!;
  static pw.Font get italic => _italic!;

  /// PDF-Generator Theme [_buildTheme]
  static Future<pw.PageTheme> loadTheme(
    PdfPageFormat pageFormat, {
    pw.Widget Function(pw.Context)? buildBackground,
  }) async {
    await FontManager.loadFonts();

    return pw.PageTheme(
      pageFormat: pageFormat,
      theme: pw.ThemeData.withFont(
        base: FontManager.base,
        bold: FontManager.bold,
        italic: FontManager.italic,
      ),
      buildBackground: buildBackground,
    );
  }
}
