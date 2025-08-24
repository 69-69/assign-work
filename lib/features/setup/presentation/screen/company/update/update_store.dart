import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/setup/data/models/company_stores_model.dart';
import 'package:assign_erp/features/setup/data/models/index.dart';
import 'package:assign_erp/features/setup/presentation/bloc/company/company_stores_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/setup/presentation/screen/company/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateStore<T> on BuildContext {
  Future<void> openUpdateStore({required CompanyStores store}) =>
      openBottomSheet(
        isExpand: false,
        child: FormBottomSheet(
          title: 'Edit Store',
          subtitle: store.name.toTitleCase,
          body: _UpdateStoreForm(store: store),
        ),
      );
}

class _UpdateStoreForm extends StatefulWidget {
  final CompanyStores store;

  const _UpdateStoreForm({required this.store});

  @override
  State<_UpdateStoreForm> createState() => _UpdateStoreFormState();
}

class _UpdateStoreFormState extends State<_UpdateStoreForm> {
  CompanyStores get _store => widget.store;

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: _store.name);
  late final _phoneController = TextEditingController(text: _store.phone);
  late final _locationController = TextEditingController(text: _store.location);
  late final _remarksController = TextEditingController(text: _store.notes);

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final item = _store.copyWith(
        name: _nameController.text,
        phone: _phoneController.text,
        location: _locationController.text,
        notes: _remarksController.text,
        createdBy: _store.createdBy,
        updatedBy: context.employee!.fullName,
      );

      /// Update store
      context.read<CompanyStoresBloc>().add(
        UpdateSetup<CompanyStores>(documentId: _store.id, data: item),
      );

      context.showAlertOverlay(
        '${_nameController.text.toTitleCase} successfully updated',
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(context),
    );
  }

  Column _buildBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const SizedBox(height: 20.0),
        StoreNameAndLocationInput(
          nameController: _nameController,
          locationController: _locationController,
          onNameChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
          onLocationChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        PhoneTextField(
          controller: _phoneController,
          onChanged: (s) => setState(() {}),
        ),
        const SizedBox(height: 20.0),
        RemarksTextField(controller: _remarksController),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(onPressed: _onSubmit),
      ],
    );
  }
}
