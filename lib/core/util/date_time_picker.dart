import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:flutter/material.dart';

var _nowToday = DateTime.now();
/*getFormattedDate() {
  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy, M, d').format(now);
  return formattedDate;
}*/

/// Date Picker [DatePicker]
class DatePicker extends StatefulWidget {
  const DatePicker({
    super.key,
    this.label,
    this.initialDate,
    this.restorationId,
    required this.selectedDate,
    this.validator,
    this.helperText,
    this.isButton = false,
    this.inLabel = true,
    this.showAlert = false,
  });

  final String? label;
  final bool isButton;

  /// [inLabel] If TRUE `helperText` is applied to the label, else to the input field.
  final bool inLabel;
  final bool showAlert;
  final String? helperText;
  final String? initialDate;
  final String? restorationId;
  final Function(DateTime) selectedDate;
  final String? Function(String?)? validator;

  @override
  State<DatePicker> createState() => _DatePickerState();
}

/// RestorationProperty objects can be used because of RestorationMixin.
class _DatePickerState extends State<DatePicker> with RestorationMixin {
  late final _textController = TextEditingController(
    text: widget.initialDate ?? '',
  );

  // In this example, the restoration ID for the mixin is passed in through
  // the [StatefulWidget]'s constructor.
  @override
  String? get restorationId => widget.restorationId;

  final RestorableDateTime _selectedDate = RestorableDateTime(
    DateTime(_nowToday.year, _nowToday.month, _nowToday.day),
  );
  late final RestorableRouteFuture<DateTime?> _restorableDatePickerRouteFuture =
      RestorableRouteFuture<DateTime?>(
        onComplete: _selectDate,
        onPresent: (NavigatorState navigator, Object? arguments) {
          return navigator.restorablePush(
            _datePickerRoute,
            arguments: _selectedDate.value.millisecondsSinceEpoch,
          );
        },
      );

  @pragma('vm:entry-point')
  static Route<DateTime> _datePickerRoute(
    BuildContext context,
    Object? arguments,
  ) {
    return DialogRoute<DateTime>(
      context: context,
      builder: (BuildContext context) => DatePickerDialog(
        restorationId: 'date_picker_dialog',
        initialEntryMode: DatePickerEntryMode.calendar,
        initialDate: DateTime.fromMillisecondsSinceEpoch(arguments! as int),
        firstDate: DateTime(_nowToday.year),
        lastDate: DateTime(_nowToday.year + 3),
      ),
    );
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_selectedDate, 'selected_date');
    registerForRestoration(
      _restorableDatePickerRouteFuture,
      'date_picker_route_future',
    );
  }

  void _selectDate(DateTime? newSelectedDate) {
    if (newSelectedDate != null) {
      setState(() {
        _selectedDate.value = newSelectedDate;

        var selectedDate =
            '${_selectedDate.value.day}/'
            '${_selectedDate.value.month}/'
            '${_selectedDate.value.year}';

        _textController.text = selectedDate;

        // Return DateTime
        widget.selectedDate(_selectedDate.value);

        if (widget.showAlert) {
          context.showAlertOverlay(
            'Selected: ${_selectedDate.value.day}/'
            '${_selectedDate.value.month}/'
            '${_selectedDate.value.year}',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.isButton ? _buildIconButton() : _buildTextField(context);
  }

  IconButton _buildIconButton() {
    return IconButton(
      tooltip: 'Search by Date',
      onPressed: () => _restorableDatePickerRouteFuture.present(),
      icon: const Icon(Icons.date_range),
      style: IconButton.styleFrom(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        ),
        backgroundColor: kGrayColor.toAlpha(0.1),
      ),
    );
  }

  _buildTextField(BuildContext context) {
    return TextFormField(
      controller: _textController,
      onTap: () => _restorableDatePickerRouteFuture.present(),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: TextInputType.datetime,
      decoration: inputDecoration,
      validator: widget.validator ?? (String? v) => v == null ? "" : null,
    );
  }

  InputDecoration get inputDecoration {
    String? helpText;
    if (widget.helperText != null) {
      helpText = widget.inLabel ? '(${widget.helperText})' : widget.helperText;
    }

    return InputDecoration(
      labelText: widget.label ?? 'Date Picker ${helpText ?? ''}',
      hintText: '01/26/${_nowToday.year}',
      helperText: helpText,
      suffixIcon: IconButton(
        tooltip: helpText ?? 'Click to show Date Picker',
        icon: const Icon(Icons.date_range),
        onPressed: () => _restorableDatePickerRouteFuture.present(),
        style: IconButton.styleFrom(shape: const RoundedRectangleBorder()),
      ),
      // contentPadding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 15.0),
      labelStyle: TextStyle(color: context.onSurfaceColor),
      hintStyle: TextStyle(fontWeight: FontWeight.normal),
    );
  }
}

/// Time Picker [TimePicker]
class TimePicker extends StatefulWidget {
  const TimePicker({
    super.key,
    this.serverTime,
    required this.selectedTime,
    required this.validator,
    this.helperText,
    this.showAlert = false,
  });

  final bool showAlert;
  final String? serverTime;
  final String? helperText;
  final Function(String) selectedTime;
  final String? Function(String?)? validator;

  @override
  State<TimePicker> createState() => _TimePickerState();
}

class _TimePickerState extends State<TimePicker> {
  TimeOfDay _selectedTime = TimeOfDay.now();
  late final _textController = TextEditingController(
    text: widget.serverTime ?? '',
  );

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
        _textController.text = picked.format(context);

        // Return input value
        widget.selectedTime(picked.format(context));

        if (widget.showAlert) {
          context.showAlertOverlay('Selected: ${picked.format(context)}');
        }
      });
    }
  }

  get _helpText => widget.helperText != null
      ? '(${widget.helperText})'
      : 'Click to show Time Picker';

  @override
  Widget build(BuildContext context) {
    return _buildTextField(context);
  }

  _buildTextField(BuildContext context) {
    // final helpText = widget.helperText != null ? '(${widget.helperText})' : '';

    return TextFormField(
      controller: _textController,
      onTap: () => _selectTime(context),
      keyboardType: TextInputType.datetime,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      // cursorColor: kLightColor,
      // style: const TextStyle(color: kLightColor),
      decoration: inputDecoration.copyWith(
        hintText: _helpText,
        // helperText: widget.helperText,
      ),
      validator: widget.validator ?? (String? v) => v == null ? "" : null,
    );
  }

  InputDecoration get inputDecoration {
    return InputDecoration(
      isDense: false,
      // fillColor: kLightColor,
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(/*color: kLightColor, */ width: 1.0),
      ),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(/*color: kLightColor, */ width: 1.0),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 5.0,
        vertical: 15.0,
      ),

      suffixIcon: IconButton(
        tooltip: _helpText,
        icon: const Icon(Icons.access_time),
        onPressed: () => _selectTime(context),
      ),
      labelStyle: TextStyle(color: context.onSurfaceColor),
      hintStyle: const TextStyle(
        // color: kLightColor,
        fontWeight: FontWeight.normal,
      ),
    );
  }
}
