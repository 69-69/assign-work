mixin Exportable {
  /// Headers for CSV / Excel / PDF
  List<String> get exportHeaders;

  /// Headers for CSV / Excel
  Map<String, dynamic> get templateHeaders;

  /// Optional: Convert model instance to list of values
  List<String> toExportRow();
}