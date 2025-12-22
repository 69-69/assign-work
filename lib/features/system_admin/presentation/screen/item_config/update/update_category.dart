import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_scaffold.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/features/auth/presentation/guard/auth_guard.dart';
import 'package:assign_erp/features/system_admin/data/models/index.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/item_config/category_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/item_config/widget/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateCategory on BuildContext {
  Future openUpdateCategory({required Category category}) => openBottomSheet(
    isExpand: false,
    child: BottomSheetScaffold(
      title: 'Edit Category',
      subtitle: category.name.toTitle,
      body: _UpdateCategoryForm(category: category),
    ),
  );
}

class _UpdateCategoryForm extends StatefulWidget {
  final Category category;

  const _UpdateCategoryForm({required this.category});

  @override
  State<_UpdateCategoryForm> createState() => _UpdateCategoryFormState();
}

class _UpdateCategoryFormState extends State<_UpdateCategoryForm> {
  Category get _category => widget.category;

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: _category.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final item = _category.copyWith(
        name: _nameController.text,
        createdBy: _category.createdBy,
        updatedBy: context.employee!.fullName,
      );

      /// Update Category
      context.read<CategoryBloc>().add(
        UpdateSetup<Category>(documentId: _category.id, data: item),
      );

      context.showAlertOverlay(
        '${_nameController.text.toTitle} successfully updated',
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
        CategoryTextField(
          controller: _nameController,
          onChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 10.0),
        context.confirmableActionButton(onPressed: _onSubmit),
      ],
    );
  }
}
