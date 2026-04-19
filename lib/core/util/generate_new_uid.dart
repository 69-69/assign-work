import 'dart:math';

import 'package:assign_erp/core/constants/app_db_collect.dart';
import 'package:assign_erp/core/network/data_sources/remote/bloc/firestore_bloc.dart';
import 'package:assign_erp/core/network/data_sources/remote/bloc/short_id_bloc.dart';
import 'package:assign_erp/core/util/extensions/doc_type_enum.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/features/inventory_ims/data/models/short_id_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

extension GenerateUID on DocType {
  static final _dbCollectionPaths = {
    DocType.work: workspaceAccDBColPath,
    DocType.item: itemsDBColPath,
    DocType.order: ordersDBColPath,
    DocType.purchase: purchaseOrdersDBColPath,
    DocType.misc: miscOrdersDBColPath,
    DocType.rfq: requestPriceQuoteDBColPath,
    DocType.prs: purchaseRequisitionDBColPath,
    DocType.sale: salesDBColPath,
    DocType.sQuote: salesQuotationDBColPath,
    DocType.delivery: deliveryDBColPath,
    DocType.invoice: invoiceDBColPath,
    DocType.customer: customersDBColPath,
    DocType.pOrder: posOrdersDBColPath,
    DocType.itemMaster: itemMasterDBColPath,
    DocType.warehouse: warehouseDBColPath,
    DocType.whLocation: whStorageLocationDBColPath,
    DocType.whBin: whBinStorageDBColPath,
    DocType.pSale: posSalesDBColPath,
    DocType.employee: employeesDBColPath,
  };

  String get _dbCollectionPath => _dbCollectionPaths[this] ?? 'unknownPath';

  Future<String> _checkReturn() async {
    final shortIdBloc = ShortIDBloc(
      _dbCollectionPath,
      firestore: FirebaseFirestore.instance,
    );
    shortIdBloc.add(GetShortID<ShortUID>());

    final allData =
        await shortIdBloc.stream.firstWhere(
              (state) => state is ItemLoaded<ShortUID>,
            )
            as ItemLoaded<ShortUID>;

    return allData.data.shortId;
  }

  Future<String?> _generateAndHandleId({Function(String)? onChanged}) async {
    final newId = await _checkReturn();

    if (newId.isNotEmpty) {
      final prefix = getName.isNotEmpty
          ? getName.substring(0, 3).toUpperAll
          : '';
      final formattedId = '$prefix-$newId';

      if (onChanged != null) {
        onChanged(formattedId);
      } else {
        return formattedId;
      }
    }
    return null;
  }

  Future<String?> getShortStr() async => _generateAndHandleId();

  Future<void> getShortUID({required Function(String) onChanged}) async =>
      await _generateAndHandleId(onChanged: onChanged);
}

extension UniqueCodeExtension on String {
  /// Generates a simple, unique numeric department/store/supplier code,
  /// optionally prefixed with an abbreviation.
  /// The numeric part checks against all existing codes, ignoring prefixes.
  /// @example 'Sales'.nextCode(existingCodes: ['SAL-6300', 'HR-6301'])
  String nextCode({List<String>? existingCodes, int startPoint = 1200}) {
    final prefix = this;

    existingCodes ??= [];

    if (existingCodes.isNotEmpty) {
      // Extract numeric part from all existing codes, ignore prefixes
      final existingNumbers = existingCodes
          .map((c) {
        // Split by '-' and take the last segment
        final parts = c.split('-');
        return int.tryParse(parts.last);
      })
          .where((n) => n != null)
          .cast<int>()
          .toList();

      if (existingNumbers.isNotEmpty) {
        startPoint = existingNumbers.reduce((a, b) => a > b ? a : b) + 1;
      }
    }

    String abbreviation = _abbrev(prefix);

    final code = startPoint.toString();
    return abbreviation.isNotEmpty ? '$abbreviation-$code' : code;
  }

  /// Generates a unique department code based on the provided name and existing codes [generateUniqueCode].
  /// @param name The name of the department.
  /// @param existingCodes (Optional) A list of existing department codes.
  /// @return The generated department code.
  /// @throws Exception if the name is empty.
  /// @example 'Sales'.generateUniqueCode()
  ///
  String generateUniqueCode([List<String>? existingCodes]) {
    final prefix = this;
    if (prefix.trim().isEmpty) return '';

    existingCodes ??= []; // Default to empty list if null

    String abbreviation = _abbrev(prefix);

    // Step 2: Generate a unique code
    final d = DateTime.now();
    String shortPad = '-${d.second}${d.minute}-${d.year}${d.hour}${d.day}';

    String candidate;
    do {
      candidate = abbreviation + shortPad;
    } while (existingCodes.contains(candidate));

    return candidate;
  }

  String _abbrev(String prefix) {
    final words = prefix
        .trim()
        .toUpperCase()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    // Step 1: Build abbreviation
    String abbreviation;
    if (words.length == 1) {
      // No spaces — take first 3 characters
      abbreviation = words.first.substring(0, words.first.length.clamp(1, 3));
    } else {
      // Take first letter of each word
      abbreviation = words.map((word) => word[0]).join();
    }
    return abbreviation;
  }

  /// [generateTaxCode] Generates a unique tax code based on the provided name and rate.
  String generateTaxCode(dynamic rate) {
    // Trim, lowercase, and replace spaces with underscores
    final name = trim().toLowerAll.replaceAll(RegExp(r'\s+'), '_');
    // Replace any non-alphanumeric characters with underscores
    final newRate = rate.toString().replaceAll('.', '-');
    return '${name}_$newRate';
  }

  /// [_nextTerm] Find & generate the next code based on existing codes & optional separator
  /// @param existingCodes (Optional) A list of existing codes.
  /// @param prefix The prefix for the code.
  /// @return The generated code.
  /// @example _nextCode(['WH01', 'WH02'], 'WH')
  //// OUTPUT: WH03
  String _nextTerm(List<String>? existingCodes, {String separator = ''}) {
    final prefix = this;
    existingCodes ??= [];

    // Extract numbers from codes that start with this prefix
    final numbers = existingCodes.where((c) => c.startsWith(prefix)).map((c) {
      if (separator.isEmpty) {
        // No separator: remove prefix
        return int.tryParse(c.replaceFirst(prefix, '')) ?? 0;
      } else {
        // Separator exists: take last segment after separator
        final parts = c.split(separator);
        return int.tryParse(parts.last) ?? 0;
      }
    });

    // Find max and add 1
    final next = numbers.isEmpty ? 1 : (numbers.reduce(max) + 1);

    // Return formatted code
    return '$prefix$separator${next.toString().padLeft(2, '0')}'.toUpperAll;
  }

  /// [nextWarehouseCode] @example 'WH'.nextWarehouseCode(['WH01', 'WH02'])
  /// OUTPUT: WH03
  String nextWarehouseCode([List<String>? existingCodes]) =>
      _nextTerm(existingCodes);

  /// [nextLocationCode] @example 'REC'.nextLocationCode(['REC01', 'REC02'])
  /// OUTPUT: REC03
  String nextLocationCode([List<String>? existingCodes]) =>
      _nextTerm(existingCodes);

  /// [nextBinCode] @example 'BIN'.nextBinCode(['BIN-01', 'A-01'])
  /// OUTPUT: BIN03
  String nextBinCode([List<String>? existingCodes]) =>
      _nextTerm(existingCodes, separator: '-');

  /// Example: generateRange(1, 5, prefix: 'A')
  /// OUTPUT: ['A01', 'A02', 'A03', 'A04', 'A05']
  List<String> generateRange(int start, int end, {int pad = 2}) {
    String prefix = this;
    return List.generate(
      end - start + 1,
      (i) => '$prefix${(start + i).toString().padLeft(pad, '0')}',
    );
  }

  List<String> nextRangeAfterExisting(
    int count, {
    int pad = 2,
    List<String>? existingCodes,
  }) {
    final prefix = this;
    existingCodes ??= [];

    // Extract numeric parts
    final numbers = existingCodes
        .where((c) => c.startsWith(prefix))
        .map((c) => int.tryParse(c.replaceFirst(prefix, '')) ?? 0);

    final start = numbers.isEmpty ? 1 : numbers.reduce(max) + 1;

    return List.generate(
      count,
      (i) => '$prefix${(start + i).toString().padLeft(pad, '0')}',
    );
  }
}

/// Generates a list of codes between [from] and [to] (inclusive).
List<String> generateBinLocationsCode(String from, String to) {
  // Example: from = "A01", to = "A03"
  final prefix = from.replaceAll(RegExp(r'\d+$'), '');
  final startNum = from.replaceAll(RegExp(r'\D'), '').asInt;
  final endNum = to.replaceAll(RegExp(r'\D'), '').asInt;

  if (startNum > endNum) return [];

  return List.generate(
    endNum - startNum + 1,
    (i) => '$prefix${(startNum + i).toString().padLeft(2, '0')}',
  );
}

/// Combines multiple levels of codes into a cartesian product with "-" separator
List<String> combineLevels(List<List<String>> lists, [String prefix = '']) {
  if (lists.isEmpty) return [prefix.substring(1)]; // remove leading '-'
  List<String> result = [];
  for (final item in lists.first) {
    result.addAll(combineLevels(lists.sublist(1), '$prefix-$item'));
  }
  return result;
}
