import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/date_time_picker.dart';
import 'package:assign_erp/core/util/extensions/discount_type.dart';
import 'package:assign_erp/core/util/format_date_utl.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/form/custom_checkbox_tile.dart';
import 'package:assign_erp/core/widgets/form/discount_type_dropdown.dart';
import 'package:assign_erp/core/widgets/form/transaction_type_dropdown.dart';
import 'package:assign_erp/core/widgets/text_field/dynamic_text_fields.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/pricing_discount_master/widget/search_discount_group.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/pricing_discount_master/widget/search_price_list.dart';
import 'package:flutter/material.dart';

class DiscountFormInputs {
  /// Discount Group
  static List<FieldGroupConfig> get discountGroupFields => [
    FieldGroupConfig(
      key: 'transactionType',
      label: 'Transaction type',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return TransactionTypeDropdown(
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),
    FieldGroupConfig(
      key: 'name',
      label: 'Discount name',
      type: TextInputType.text,
      helperText: 'E.g.: Promo, Holiday Sale, or VIP Discount',
    ),
    ...validityDateFields,
    FieldGroupConfig(
      key: 'description',
      label: 'Optional notes or details about this discount group',
      type: TextInputType.multiline,
      isTextArea: true,
      isAutoGrow: true,
      minLines: null,
      validator: (_) => null,
    ),
  ];

  ///Discount Rule
  static List<FieldGroupConfig> get discountRuleFields => [
    FieldGroupConfig(
      key: 'discountType',
      label: 'Discount type',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return DiscountTypeDropdown(
          initialValue: initialData,
          onChanged: (String? selected) => onChanged(selected),
        );
      },
    ),

    FieldGroupConfig(
      key: 'isStackable',
      label: 'Stackable Discount',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        bool isChecked = initialData ?? false; // local state

        return StatefulBuilder(
          builder: (context, setState) {
            return CustomCheckboxTile(
              title: Text(
                'Allow Stacking',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                'Can this discount be combined with other active discounts?',
              ),
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
      key: 'discountGroupId',
      label: 'Discount Group',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return SearchDiscountGroup(
          initialValue: initialData,
          onChanged: (String id, String name) => onChanged(id),
        );
      },
    ),

    FieldGroupConfig(
      key: 'priceListId',
      label: 'Price List',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        return SearchPriceList(
          initialValue: initialData,
          onChanged: (String id, String name) => onChanged(id),
        );
      },
    ),

    FieldGroupConfig(
      key: 'discountValue',
      label: 'Discount',
      type: TextInputType.number,
      helperText: 'Discount amount, percentage, or override value',
    ),
    FieldGroupConfig(
      key: 'minQuantity',
      label: 'Minimum Quantity',
      type: TextInputType.number,
      helperText: 'Minimum quantity required before this discount applies',
    ),

    ...validityDateFields,

    FieldGroupConfig(
      key: 'couponCode',
      label: 'Coupon Code',
      type: TextInputType.none,
      helperText: 'Coupon or promo code customers will use',
      visibleWhen: (data) => DiscountTypeUtil.isCoupon(data['discountType']),
    ),
  ];

  /// Dates & Validity
  static List<FieldGroupConfig> get validityDateFields => [
    FieldGroupConfig(
      key: 'validFrom',
      label: 'Start date',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final msg = 'The date this discount becomes active';

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
      label: 'End date',
      type: TextInputType.text,
      widgetType: FieldWidgetType.custom,
      customBuilder: ({required initialData, required onChanged}) {
        final msg = 'The date this discount expires';

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
