import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/bottom_sheet_header.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/user_guide/data/models/user_guide_model.dart';
import 'package:assign_erp/features/user_guide/presentation/bloc/index.dart';
import 'package:assign_erp/features/user_guide/presentation/bloc/user_guide_bloc.dart';
import 'package:assign_erp/features/user_guide/presentation/screen/how_to_config_app/widgets/user_guide_form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension UpdateUserGuideForm<T> on BuildContext {
  Future<void> openUpdateUserGuide({required UserGuide guide}) =>
      openBottomSheet(isExpand: false, child: _UpdateUserGuide(guide: guide));
}

class _UpdateUserGuide extends StatelessWidget {
  final UserGuide guide;

  const _UpdateUserGuide({required this.guide});

  @override
  Widget build(BuildContext context) {
    return CustomDraggableBottomSheet(
      padding: EdgeInsets.only(bottom: context.bottomInsetPadding),
      initialChildSize: 0.90,
      maxChildSize: 0.90,
      header: _buildHeader(context),
      child: _buildBody(context),
    );
  }

  DialogHeader _buildHeader(BuildContext context) {
    return DialogHeader(
      title: ListTile(
        dense: true,
        title: Text(
          'Edit Guide',
          textAlign: TextAlign.center,
          style: context.textTheme.titleLarge?.copyWith(color: kGrayColor),
        ),
        subtitle: Text(
          guide.title.toTitle,
          textAlign: TextAlign.center,
          style: context.textTheme.titleMedium?.copyWith(color: kGrayColor),
        ),
      ),
      btnText: 'Delete',
      onCancel: () => _onDeleteTap(context),
    );
  }

  Future<void> _onDeleteTap(BuildContext context) async {
    final isConfirmed = await context.confirmUserActionDialog();

    if (context.mounted && isConfirmed) {
      // Dispatch the delete event
      context.read<HowToBloc>().add(
        DeleteGuide<UserGuide>(documentId: guide.id),
      );
      Navigator.pop(context);
    }
  }

  _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
      child: _UpdateUserGuideBody(guide: guide),
    );
  }
}

class _UpdateUserGuideBody extends StatefulWidget {
  final UserGuide guide;

  const _UpdateUserGuideBody({required this.guide});

  @override
  State<_UpdateUserGuideBody> createState() => _UpdateUserGuideBodyState();
}

class _UpdateUserGuideBodyState extends State<_UpdateUserGuideBody> {
  UserGuide get _guide => widget.guide;

  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;

  late final _guideIdController = TextEditingController(text: _guide.id);
  late final _urlController = TextEditingController(text: _guide.url);

  late final _descController = TextEditingController(text: _guide.description);
  late final _titleController = TextEditingController(text: _guide.title);

  @override
  void dispose() {
    _guideIdController.dispose();
    _urlController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final item = _guide.copyWith(
        category: _selectedCategory ?? _guide.category,
        id: _guideIdController.text,
        url: _urlController.text,
        description: _descController.text,
        title: _titleController.text,
      );

      /// Update User Guide
      context.read<HowToBloc>().add(
        UpdateGuide<UserGuide>(documentId: _guide.id, data: item),
      );

      _formKey.currentState!.reset();
      context.showAlertOverlay('${_guide.title} has been successfully updated');

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: _buildBody(),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TitleCategoryInput(
          titleController: _titleController,
          serverCategory: _guide.category,
          onCategoryChange: (t) => setState(() => _selectedCategory = t),
          onTitleChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        UrlTextField(
          controller: _urlController,
          onChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        DescTextField(
          descController: _descController,
          onDescChanged: (v) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(onPressed: _onSubmit),
      ],
    );
  }
}
