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
    DocType.whLocation: whLocationStorageDBColPath,
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
  /// Generates a unique department code based on the provided name and existing codes [generateUniqueCode].
  /// @param name The name of the department.
  /// @param existingCodes (Optional) A list of existing department codes.
  /// @return The generated department code.
  /// @throws Exception if the name is empty.
  /// @example 'Sales'.generateUniqueCode()
  ///
  String generateUniqueCode([List<String>? existingCodes]) {
    final name = this;
    if (name.trim().isEmpty) return '';

    existingCodes ??= []; // Default to empty list if null

    final words = name
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

    // Step 2: Generate a unique code
    final d = DateTime.now();
    String shortPad = '-${d.second}${d.minute}-${d.year}${d.hour}${d.day}';

    String candidate;
    do {
      candidate = abbreviation + shortPad;
    } while (existingCodes.contains(candidate));

    return candidate;
  }

  /// [generateTaxCode] Generates a unique tax code based on the provided name and rate.
  String generateTaxCode(dynamic rate) {
    // Trim, lowercase, and replace spaces with underscores
    final name = trim().toLowerAll.replaceAll(RegExp(r'\s+'), '_');
    // Replace any non-alphanumeric characters with underscores
    final newRate = rate.toString().replaceAll('.', '-');
    return '${name}_$newRate';
  }

  /// [_nextCode] Find & generate the next code based on existing codes & optional separator
  /// @param existingCodes (Optional) A list of existing codes.
  /// @param prefix The prefix for the code.
  /// @return The generated code.
  /// @example _nextCode(['WH01', 'WH02'], 'WH')
  //// OUTPUT: WH03
  String _nextCode(List<String>? existingCodes, {String separator = ''}) {
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
      _nextCode(existingCodes);

  /// [nextLocationCode] @example 'REC'.nextLocationCode(['REC01', 'REC02'])
  /// OUTPUT: REC03
  String nextLocationCode([List<String>? existingCodes]) =>
      _nextCode(existingCodes);

  /// [nextBinCode] @example 'BIN'.nextBinCode(['BIN-01', 'A-01'])
  /// OUTPUT: BIN03
  String nextBinCode([List<String>? existingCodes]) =>
      _nextCode(existingCodes, separator: '-');

  /// Example: generateRange(1, 5)
  /// OUTPUT: ['01', '02', '03', '04', '05']
  List<String> generateRange(int start, int end, {int pad = 2}) {
    return List.generate(
      end - start + 1,
      (i) => (start + i).toString().padLeft(pad, '0'),
    );
  }
}

/// Warehouse Location Code Generator
List<String> generateLocationCodes({
  required int zoneFrom,
  required int zoneTo,
  required int aisleFrom,
  required int aisleTo,
  required int rackFrom,
  required int rackTo,
  required int levelFrom,
  required int levelTo,
  required int shelfFrom,
  required int shelfTo,
}) {
  final zones = ''.generateRange(zoneFrom, zoneTo);
  final aisles = ''.generateRange(aisleFrom, aisleTo);
  final racks = ''.generateRange(rackFrom, rackTo);
  final levels = ''.generateRange(levelFrom, levelTo);
  final shelves = ''.generateRange(shelfFrom, shelfTo);

  List<String> locations = [];

  for (var z in zones) {
    for (var a in aisles) {
      for (var r in racks) {
        for (var l in levels) {
          for (var s in shelves) {
            locations.add('Z$z-A$a-R$r-L$l-S$s');
          }
        }
      }
    }
  }

  return locations;
}

/// Example Usage
/*void main() {
  final locations = generateLocationCodes(
    zoneFrom: 1,
    zoneTo: 2,
    aisleFrom: 1,
    aisleTo: 2,
    rackFrom: 1,
    rackTo: 3,
    levelFrom: 1,
    levelTo: 2,
    shelfFrom: 1,
    shelfTo: 2,
  );

  for (var loc in locations) {
    print(loc);
  }
}
/// Sample Output
Z01-A01-R01-L01-S01
Z01-A01-R01-L01-S02
Z01-A01-R01-L02-S01
Z01-A01-R01-L02-S02
Z01-A01-R02-L01-S01
...
Z02-A02-R03-L02-S02
*/
