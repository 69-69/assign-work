import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/category_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/category_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/ref_master/create/create_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AllCategories extends StatefulWidget {
  final bool isService;

  const AllCategories({super.key, this.isService = false});

  @override
  State<AllCategories> createState() => _AllCategoriesState();
}

class _AllCategoriesState extends State<AllCategories> {
  List<String> _selectedIds = [];

  bool get _isService => widget.isService;

  CategoryBloc get _bloc => context.read<CategoryBloc>();

  @override
  Widget build(BuildContext context) {
    return _buildBody();
  }

  BlocBuilder<CategoryBloc, SetupState<Category>> _buildBody() {
    return BlocBuilder<CategoryBloc, SetupState<Category>>(
      builder: (context, state) {
        final isDeleting = state is SetupDeleting<Category>;
        /*if (state is SetupsLoaded<Category>) {
          setState(() => _selectedIds.clear());
        }*/

        return switch (state) {
          SetupDeleting<Category>() => context.loader,
          LoadingSetup<Category>() => context.loader,
          SetupsLoaded<Category>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'New Category',
                    onPressed: () => context.openAddCategory(),
                  )
                : _buildCard(context, results, isDeleting: isDeleting),
          SetupError<Category>(error: final error) => context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  List<DataTableRow> _filterCategories(List<Category> cats) {
    return (_isService
            ? Category.filterServiceCategories(cats)
            : Category.filterMaterialCategories(cats))
        .map(_toTableRow)
        .toList();
  }

  Widget _buildCard(
    BuildContext c,
    List<Category> categories, {
    bool isDeleting = false,
  }) {
    return DynamicDataTable2(
      omitAtIndex: 0,
      headers: Category.dataHeader,
      toolbar: _buildToolbar(categories, isDeleting),
      rows: _filterCategories(categories),
      selectedRowKeys: _selectedIds,
      onSelectionChanged: (ids, rows) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          setState(() => _selectedIds = ids);
        });
      },
      onEditTap: (row) async => _onEditTap(categories, row.id),
      onDeleteTap: (row) async => _onDeleteTap(categories, row.id),
    );
  }

  DataTableRow _toTableRow(Category e) =>
      DataTableRow.fromList(e.id, e.itemAsList);

  _buildToolbar(List<Category> categories, bool isDeleting) {
    return ListToolbarButtons(
      primaryLabel: 'New Category',
      refreshLabel: 'Refresh',
      dataLength: categories.length,
      dangerLabel: isDeleting ? 'Deleting...' : 'Delete',
      onPrimary: () => context.openAddCategory(),
      onRefresh: () => _bloc.add(RefreshSetups<Category>()),
      onDanger: _selectedIds.isNotEmpty
          ? () async {
              final isConfirmed = await context.confirmUserActionDialog();
              if (mounted && isConfirmed) {
                _bloc.add(DeleteSetup<List<String>>(documentId: _selectedIds));
              }
            }
          : null,
    );
  }

  Future<void> _onEditTap(List<Category> categories, String id) async {
    final category = Category.findCategoriesById(categories, id).first;
    await context.openAddCategory(serverAttribute: category);
  }

  Future<void> _onDeleteTap(List<Category> categories, String id) async {
    final category = Category.findCategoriesById(categories, id).first;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Delete specific category
      _bloc.add(DeleteSetup<String>(documentId: category.id));
    }
  }
}
