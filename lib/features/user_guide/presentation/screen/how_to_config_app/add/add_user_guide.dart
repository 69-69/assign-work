import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/custom_scroll_bar.dart';
import 'package:assign_erp/core/widgets/custom_snack_bar.dart';
import 'package:assign_erp/core/widgets/dialog/custom_bottom_sheet.dart';
import 'package:assign_erp/core/widgets/dialog/form_bottom_sheet.dart';
import 'package:assign_erp/features/user_guide/data/models/user_guide_model.dart';
import 'package:assign_erp/features/user_guide/presentation/bloc/index.dart';
import 'package:assign_erp/features/user_guide/presentation/bloc/user_guide_bloc.dart';
import 'package:assign_erp/features/user_guide/presentation/screen/how_to_config_app/widgets/form_inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

extension AddGuideForm<T> on BuildContext {
  Future<void> openAddGuide({String? category}) => openBottomSheet(
    isExpand: false,
    child: FormBottomSheet(title: 'Create User Guide', body: _AddGuideForm()),
  );
}

class _AddGuideForm extends StatefulWidget {
  const _AddGuideForm();

  @override
  State<_AddGuideForm> createState() => _AddGuideFormState();
}

class _AddGuideFormState extends State<_AddGuideForm> {
  final ScrollController _scrollController = ScrollController();
  bool isMultipleGuides = false;
  final List<UserGuide> _userGuides = [];
  final _formKey = GlobalKey<FormState>();
  String _selectedCategory = '';
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  UserGuide get _guideData => UserGuide(
    url: _urlController.text,
    title: _titleController.text,
    category: _selectedCategory,
    description: _descriptionController.text,
  );

  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      /// Added Multiple Products Simultaneously
      _userGuides.add(_guideData);

      // Create New Guide
      context.read<HowToBloc>().add(
        AddGuide<List<UserGuide>>(data: _userGuides),
      );

      _formKey.currentState!.reset();
      context.showAlertOverlay(
        '${_titleController.text.toTitleCase} successfully created',
      );

      Navigator.of(context).pop();
    }
  }

  /// Adds the current Guide form data to the batch list for later submission
  void _addGuideToList() {
    if (_formKey.currentState!.validate()) {
      setState(() => isMultipleGuides = true);
      _userGuides.add(_guideData);

      context.showAlertOverlay(
        '${_titleController.text.toTitleCase} added to batch',
      );
      _clearFields();
    }
  }

  void _clearFields() {
    _titleController.clear();
    _urlController.clear();
    _descriptionController.clear();
    _selectedCategory = '';
  }

  void _removeGuide(UserGuide guide) {
    setState(() => _userGuides.remove(guide));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Wrap(
        // runSpacing: 20,
        alignment: WrapAlignment.center,
        children: [
          if (isMultipleGuides && _userGuides.isNotEmpty) ...[
            SizedBox(height: 60, child: _buildGuidePreviewChips()),
          ],
          _buildBody(),
        ],
      ),
    );
  }

  // Horizontal scrollable row of chips representing the List of batch of Guides
  Widget _buildGuidePreviewChips() {
    return CustomScrollBar(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _userGuides.map((o) {
          return o.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Chip(
                    padding: EdgeInsets.zero,
                    label: Text(
                      o.title.toTitleCase,
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    deleteButtonTooltipMessage: 'Remove ${o.title}',
                    backgroundColor: kGrayColor.toAlpha(0.3),
                    deleteIcon: const Icon(
                      size: 16,
                      Icons.clear,
                      color: kGrayColor,
                    ),
                    onDeleted: () => _removeGuide(o),
                  ),
                );
        }).toList(),
      ),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Create Guide', style: context.textTheme.titleLarge),
        TitleCategoryInput(
          titleController: _titleController,
          onCategoryChange: (t) => setState(() => _selectedCategory = t),
          onTitleChanged: (s) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        UrlTextField(
          controller: _urlController,
          onChanged: (t) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        DescTextField(
          descController: _descriptionController,
          onDescChanged: (v) {
            if (_formKey.currentState!.validate()) setState(() {});
          },
        ),
        const SizedBox(height: 20.0),
        context.elevatedIconBtn(
          Icons.add,
          onPressed: _addGuideToList,
          label: 'Add to List',
        ),
        const SizedBox(height: 20.0),
        context.confirmableActionButton(
          label: isMultipleGuides ? 'Create All Guides' : 'Create Guide',
          onPressed: _onSubmit,
        ),
        const SizedBox(height: 20.0),
      ],
    );
  }
}
