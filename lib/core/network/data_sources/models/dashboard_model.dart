import 'package:assign_erp/core/util/str_util.dart';
import 'package:flutter/material.dart';

class DashboardTile {
  DashboardTile({
    required this.icon,
    required this.label,
    required this.action,
    this.param = const {},
    required this.access,
    this.description,
    this.hasSplit = false,
  }) : title = _splitLabel(label, hasSplit).$1 ?? label,
       subTitle = _splitLabel(label, hasSplit).$2 ?? '';

  final String label;
  final dynamic icon;

  /// Boolean flag indicating if the title want to be split into two parts(title & subtitle)
  final bool hasSplit;

  /// [access] Access level required to use this tile: Permission/License checks
  final String access;
  final dynamic action;
  final String? description;
  final Map<String, String> param;

  /// Parsed values
  final String? title;
  final String? subTitle;

  /// Split once, return structured result
  static (String? title, String? subTitle) _splitLabel(
    String label,
    bool isSplit,
  ) {
    if (!isSplit) return (null, null);

    // Split on multiple separators like '- _ . & + /'
    final parts = label.split(RegExp(r'\s*[-_.&+/]\s*'));

    final title = parts.isNotEmpty ? parts.first.trim() : '';
    final subTitle = parts.length > 1 && parts[1].trim().isNotEmpty
        ? parts[1].trim()
        : null;

    return (title, subTitle);
  }

  // RegExp to check if the label contains either . or -
  String get getTitle =>
      hasSplit && RegExp(r'[.-]').hasMatch(label) ? '$title $subTitle' : label;

  factory DashboardTile.fromMap(Map<String, dynamic> map) {
    return DashboardTile(
      hasSplit: map['hasSplit'] ?? false,
      icon: map['icon'] as IconData,
      label: map['label'] as String,
      action: map['action'] as String,
      param: createNewMap(map['param']),
      access: map['access'] ?? '',
      description: map['description'] as String?,
    );
  }

  /*
  * Filter tiles: matching or excluding labels or patterns.
  * USAGE:
  * filter(tiles, ['Home', 'Settings']);
  * --OR--
  * filter(tiles, [RegExp(r'^Admin'), RegExp(r'log$', caseSensitive: false)]);
  * --OR--
  * filter(tiles, ['Admin', 'log'], exclude: true);

  static List<DashboardTile> filter(
    List<DashboardTile> tiles,
    List<dynamic> patterns, { // Can be List<String> or List<RegExp>
    bool exclude = false,
  }) {
    bool matches(String label) {
      for (var pattern in patterns) {
        if (pattern is String && label == pattern) return true;
        if (pattern is RegExp && pattern.hasMatch(label)) return true;
      }
      return false;
    }

    return List<DashboardTile>.unmodifiable(
      tiles.where(
        (tile) => exclude ? !matches(tile.label) : matches(tile.label),
      ),
    );
  }*/
}

/*class RoleBasedDashboardTile<T> {
  final T roleInfo;
  final List<DashboardTile> tiles;

  RoleBasedDashboardTile({required this.roleInfo, required this.tiles});
}

class DashboardTileManager<T> {
  final Map<T, List<DashboardTile>> _tiles;

  DashboardTileManager({required Map<T, List<DashboardTile>> tiles})
    : _tiles = tiles;

  /// Creates a map of [RoleBasedDashboardTile] instances from the tiles data.
  Map<T, RoleBasedDashboardTile<T>> create() => {
    for (var entry in _tiles.entries)
      entry.key: RoleBasedDashboardTile<T>(
        roleInfo: entry.key,
        tiles: entry.value,
      ),
  };
}*/
