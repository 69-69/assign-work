import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_attributes.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/variant_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/variant_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/create/create_variants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListVariants extends StatefulWidget {
  const ListVariants({super.key});

  @override
  State<ListVariants> createState() => _ListVariantsState();
}

class _ListVariantsState extends State<ListVariants> {
  Future<void> _getAttributes({
    required Future<void> Function(Map<String, List<Attribute>> grouped)
    attributes,
  }) async {
    final attrs = await GetAttributes.load();
    final group = Attribute.groupByType(attrs);

    return await attributes(group);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VariantBloc>(
      create: (context) =>
      VariantBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<Variant>()),
      child: CustomScaffold(
        noAppBar: true,
        body: _buildBody(),
        bottomNavigationBar: const SizedBox.shrink(),
      ),
    );
  }

  BlocBuilder<VariantBloc, SetupState<Variant>> _buildBody() {
    return BlocBuilder<VariantBloc, SetupState<Variant>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Variant>() => context.loader,
          SetupsLoaded<Variant>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Explore Variants',
                    onPressed: () async {
                      await _getAttributes(
                        attributes: (grouped) async =>
                            await context.openAddVariant(groupedAttrs: grouped),
                      );
                    },
                  )
                : _buildCard(context, results),
          SetupError<Variant>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<Variant> variants) {
    return DynamicDataTable(
      omitAtIndex: 0,
      headers: Variant.dataHeader,
      toolbar: _buildToolbar(variants),
      rows: variants.map((cat) => cat.itemAsList).toList(),
      onDeleteTap: (row) async => _onDeleteTap(variants, row.first),
    );
  }

  _buildToolbar(List<Variant> variants) {
    return ListToolbarButtons(
      primaryLabel: 'Add Variant',
      refreshLabel: 'Refresh Variants',
      dataLength: variants.length,
      onPrimary: () async {
        await _getAttributes(
          attributes: (grouped) async =>
              await context.openAddVariant(groupedAttrs: grouped),
        );
      },
      onRefresh: () =>
          context.read<VariantBloc>().add(RefreshSetups<Variant>()),
    );
  }

  Future<void> _onDeleteTap(List<Variant> variants, String id) async {
    final variant = Variant.findVariantsById(variants, id).first;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Delete specific Variant
      context.read<VariantBloc>().add(
        DeleteSetup<String>(documentId: variant.id),
      );
    }
  }
}
