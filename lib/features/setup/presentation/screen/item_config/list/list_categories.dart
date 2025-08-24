import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/setup/data/models/category_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/product_config/category_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/setup/presentation/screen/item_config/add/add_category.dart';
import 'package:assign_erp/features/setup/presentation/screen/item_config/update/update_category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListCategories extends StatefulWidget {
  const ListCategories({super.key});

  @override
  State<ListCategories> createState() => _ListCategoriesState();
}

class _ListCategoriesState extends State<ListCategories> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<CategoryBloc>(
      create: (context) =>
          CategoryBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<Category>()),
      child: CustomScaffold(
        noAppBar: true,
        body: _buildBody(),
        bottomNavigationBar: const SizedBox.shrink(),
      ),
    );
  }

  BlocBuilder<CategoryBloc, SetupState<Category>> _buildBody() {
    return BlocBuilder<CategoryBloc, SetupState<Category>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Category>() => context.loader,
          SetupsLoaded<Category>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Category',
                    onPressed: () => context.openAddCategory(),
                  )
                : _buildCard(context, results),
          SetupError<Category>(error: final error) => context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<Category> categories) {
    return DynamicDataTable(
      skip: true,
      showIDToggle: true,
      headers: Category.dataHeader,
      anyWidget: _buildAnyWidget(categories),
      rows: categories.map((d) => d.toListL()).toList(),
      onEditTap: (row) async => _onEditTap(categories, row),
      onDeleteTap: (row) async => _onDeleteTap(categories, row),
    );
  }

  _buildAnyWidget(List<Category> sales) {
    return Wrap(
      spacing: 10.0,
      alignment: WrapAlignment.spaceBetween,
      children: [
        context.actionInfoButton(
          'Refresh Categories',
          label: 'Categories',
          count: sales.length,
          onPressed: () {
            // Refresh Product-Categories Data
            context.read<CategoryBloc>().add(RefreshSetups<Category>());
          },
        ),
        context.elevatedButton(
          'Add Categories',
          onPressed: () => context.openAddCategory(),
          bgColor: kDangerColor,
          txtColor: kLightColor,
        ),
      ],
    );
  }

  Future<void> _onEditTap(List<Category> categories, List<String> row) async {
    final category = Category.findCategoriesById(categories, row.first).first;
    await context.openUpdateCategory(category: category);
  }

  Future<void> _onDeleteTap(List<Category> categories, List<String> row) async {
    {
      final category = Category.findCategoriesById(categories, row.first).first;

      final isConfirmed = await context.confirmUserActionDialog();
      if (mounted && isConfirmed) {
        /// Delete specific category
        context.read<CategoryBloc>().add(
          DeleteSetup<String>(documentId: category.id),
        );
      }
    }
  }
}
