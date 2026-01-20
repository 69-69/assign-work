import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:flutter/material.dart';

class InventoryFormFields {
  static Widget buildNumber(
    BuildContext context, {
    String count = '',
    required String what,
    void Function()? onPressed,
  }) => Align(
    alignment: Alignment.topLeft,
    child: FittedBox(
      child: context.actionInfoButton(
        'Refresh $what',
        count: count,
        isTotal: false,
        onPressed: onPressed,
        bgColor: kPrimaryColor,
      ),
    ),
  );

  /// Updates the [list] with objects of type [T] from a list of maps.
  /// Clears the list first to prevent duplication, then adds new objects.
  /// [fromMap] converts each map entry into an object with the index as the ID.
  static updateListFromData<T>(
    List<T> list, {
    required List<Map<String, dynamic>> map,
    required T Function(Map<String, dynamic>, String) fromMap,
  }) {
    return list
      ..clear() // Clear previous entries to prevent duplication
      ..addAll(
        map
            .asMap()
            .entries
            .map((e) => fromMap(e.value, '${e.key + 1}'))
            .toList(),
      );
  }
}
