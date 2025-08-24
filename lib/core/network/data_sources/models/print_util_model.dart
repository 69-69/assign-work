import 'dart:typed_data';

import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/load_print_asset.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/setup/data/data_sources/local/printout_setup_cache_service.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';

class PrintPDFColors {
  // final String footerColorStr;
  Uint8List? logo;
  String footerImg;
  final bool isDenseLayout;
  final PdfColor blackColor;
  final PdfColor headerColor;
  final PdfColor footerColor;
  final PdfColor baseTextColor;
  final IssuerCompany company;

  // this.baseColor = PdfColors.teal, // header
  // this.accentColor = PdfColors.blueGrey900, // footer

  PrintPDFColors._({
    // required this.footerColorStr,
    required this.company,
    required this.logo,
    required this.footerImg,
    required this.isDenseLayout,
    required this.blackColor,
    required this.headerColor,
    required this.footerColor,
    required this.baseTextColor,
  });

  // Asynchronous factory constructor
  static Future<PrintPDFColors> create() async {
    final PrintoutSetupCacheService service = PrintoutSetupCacheService();
    var setup = await service.getSettings();

    // Load Printout-Assets Images
    ({String bg, Uint8List? logo}) img = await LoadPrintAsset.loadImg(
      companyLogo: setup?.companyLogo,
      replaceSvgColorHex: setup?.footerColor,
    );

    String footerImg = img.bg;
    Uint8List? logo = img.logo;
    IssuerCompany company = IssuerCompany.notFound;
    // String footerColorStr = '';
    bool isDenseLayout = true;
    PdfColor blackColor = PdfColors.black;
    PdfColor headerColor = PdfColors.teal;
    PdfColor footerColor = PdfColors.blueGrey900;
    PdfColor baseTextColor = PdfColors.white;

    if (setup != null && !setup.isColorsEmpty) {
      company = IssuerCompany(
        name: (setup.companyName ?? '').toTitleCase,
        email: setup.companyEmail ?? '',
        phone: setup.companyPhone ?? '',
        address: (setup.companyAddress ?? '').toTitleCase,
      );
      isDenseLayout = setup.layout == 'dense';
      // footerColorStr = setup.headerColor;
      headerColor = PdfColor.fromHex(setup.headerColor);
      footerColor = PdfColor.fromHex(setup.footerColor);
      baseTextColor = headerColor.isLight ? PdfColors.white : blackColor;
    }

    return PrintPDFColors._(
      // footerColorStr: footerColorStr,
      company: company,
      logo: logo,
      footerImg: footerImg,
      isDenseLayout: isDenseLayout,
      blackColor: blackColor,
      headerColor: headerColor,
      footerColor: footerColor,
      baseTextColor: baseTextColor,
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

  /*factory IssuerCompany.fromMap(Map<String, dynamic> data) => IssuerCompany(
        name: data['name'],
        email: data['email'],
        phone: data['phone'],
        address: data['address'],
      );*/

  static get notFound => const IssuerCompany(
    name: 'No Data',
    email: 'No Data',
    phone: 'No Data',
    address: 'No Data',
  );
}

/// Print Items Invoice, Proforma, RequestForQuotation, DeliveryNote [PrintItem]
class PrintItem {
  const PrintItem({
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
    required this.discountPercent,
    this.paymentTerms,
    this.deliveryAmt = 0.0,
    this.taxPercent = 0.0,
    this.validityDate,
    this.sku,
  });

  final String? sku;
  final double discountPercent;
  final String itemName;
  final double unitPrice;
  final int quantity;
  final String? validityDate;
  final double deliveryAmt;
  final double taxPercent;
  final String? paymentTerms;

  // Individual subTotal
  double get _subTotal => unitPrice * quantity;

  // discountPercent / 100 * subTotal
  double get _discountAmt => (discountPercent / 100) * _subTotal;

  /// NetPrice: Is after discount is applied to subTotal [totalNetPrice]
  double get totalNetPrice => _subTotal - _discountAmt;

  String getIndex(String label, int index) {
    // final  skuLength = sku != null ? (sku!.length ~/ 2) : 0;
    // sku?.substring(0, skuLength) ?? '';
    var count = index + 1;

    switch (label) {
      case 'sku#' || '#' || 'no':
        return count.toString();
      case 'item description' || 'item':
        return itemName;
      case 'quantity' || 'qty':
        return quantity.toString();
      case 'unit price' || 'price':
        return formatCurrency(unitPrice);
      case 'discount':
        return _formatDiscount();
      case 'net price':
        return formatCurrency(totalNetPrice);
    }
    return '';
  }

  String _formatDiscount() => discountPercent > 0
      ? '$discountPercent% = $ghanaCedis${_discountAmt.toCurrency}'
      : '';

  static String formatCurrency(double amount) =>
      amount > 0 ? '$ghanaCedis${amount.toStringAsFixed(2)}' : '';

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

  static String formatCurrency(double amount) =>
      amount > 0 ? '$ghanaCedis${amount.toCurrency}' : '';
}

/*USAGE:
late Future<PrintPDFColors2> _colorsFuture;

  @override
  void initState() {
    super.initState();
    _colorsFuture = PrintPDFColors2.create();
  }
 Text(_colorsFuture.footerColorStr);

final _colorsFuture = await PrintPDFColors2.create();
    _colorsFuture.footerColorStr;*/

/*class PrintPDFColors {
  PrintPDFColors({
    this.isDenseLayout = true,
    this.footerColorStr = '',
    this.blackColor = PdfColors.black,
    this.headerColor = PdfColors.teal,
    this.footerColor = PdfColors.blueGrey900,
    this.baseTextColor = PdfColors.white,
    // this.baseColor = PdfColors.teal, // header
    // this.accentColor = PdfColors.blueGrey900, // footer
  }) {
    baseTextColor = headerColor.isLight ? PdfColors.white : blackColor;
    create().then((setup) {
      if (setup != null && !setup.isColorsEmpty) {
        footerColorStr = setup.footerColor;
        isDenseLayout = setup.layout == 'dense';
        headerColor = PdfColor.fromHex(setup.headerColor);
        footerColor = PdfColor.fromHex(setup.footerColor);
      }
    });
  }

  // Asynchronous factory constructor
  static Future create() async {
    final PrintoutSetupService service = PrintoutSetupService();
    final setup = await service.getSettings();

    return setup;
  }

  final PdfColor blackColor; // PdfColors.black;
  late bool isDenseLayout;
  late String footerColorStr;
  late PdfColor headerColor; // PdfColors.teal;
  late PdfColor footerColor; // PdfColors.blueGrey900;
  late PdfColor baseTextColor; // headerColor.isLight ? PdfColors.white : blackColor;
}*/
