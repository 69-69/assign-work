import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/form/currency_dropdown.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:assign_erp/core/widgets/form/price_list_type_dropdown.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:flutter/material.dart';

class PriceMasterFormInputs {
  static List<FieldGroupConfig> get priceListFields => [
    FieldGroupConfig(
      key: 'taxInclusive',
      label: 'Tax Inclusive?',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        bool isChecked = initialData ?? false; // local state

        return StatefulBuilder(
          builder: (_, setState) {
            return CustomCheckboxTile(
              title: Text('Tax Inclusive?'),
              subtitle: Text('Check if tax is already included in the price list'),
              contentPadding: EdgeInsets.symmetric(horizontal: 6.0),
              value: isChecked,
              onChanged: (v) {
                setState(() => isChecked = v ?? false);
                onChanged(v ?? false); // notify parent
              },
            );
          },
        );
      },
    ),
    FieldGroupConfig(
      key: 'currencyCode',
      label: 'Currency',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return CurrencyDropdown(
          initialCurrency: initialData,
          onChanged: (({String code, String symbol, String country})? s) =>
              onChanged(s!.code),
        );
      },
    ),
    FieldGroupConfig(
      key: 'type',
      label: 'Type',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return PriceListTypeDropdown(
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'name',
      label: 'Price List name',
      type: TextInputType.text,
      helperText: 'E.g.: Promo, Wholesale, Retail, VIP Customers...',
    ),
    ...validityDateFields,
  ];

  /// Dates & Validity
  static List<FieldGroupConfig> get validityDateFields => [
    FieldGroupConfig(
      key: 'validFrom',
      label: 'Valid from',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final msg = 'The date this price list becomes active';

        return DatePicker(
          inLabel: false,
          key: Key('validFrom'),
          initialDate: initialData,
          label: 'Valid from',
          restorationId: 'Valid from',
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          helperText: msg,
          validator: (v) => v.isNullOrEmpty ? msg : null,
        );
      },
    ),
    FieldGroupConfig(
      key: 'validUntil',
      label: 'Valid until',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final msg = 'The date this price list expires';

        return DatePicker(
          inLabel: false,
          key: Key('validUntil'),
          initialDate: initialData,
          label: 'Valid until',
          restorationId: 'Valid until',
          selectedDate: (DateTime date) => onChanged(date.dateOnly),
          helperText: msg,
          validator: (v) => v.isNullOrEmpty ? msg : null,
        );
      },
    ),
  ];
}
