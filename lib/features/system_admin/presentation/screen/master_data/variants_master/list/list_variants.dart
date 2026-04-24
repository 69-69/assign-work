import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/data_sources/remote/get_attributes.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/attribute_bloc.dart';
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
    required Future<void> Function(Map<String, List<String>> grouped)
    attributes,
  }) async {
    final attrs = await GetAttributes.load();
    final group = Attribute.groupAttributes(attrs);

    return await attributes(group);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AttributeBloc>(
      create: (context) =>
          AttributeBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<Attribute>()),
      child: CustomScaffold(
        noAppBar: true,
        body: _buildBody(),
        bottomNavigationBar: const SizedBox.shrink(),
      ),
    );
  }

  BlocBuilder<AttributeBloc, SetupState<Attribute>> _buildBody() {
    return BlocBuilder<AttributeBloc, SetupState<Attribute>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Attribute>() => context.loader,
          SetupsLoaded<Attribute>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Create Variant',
                    onPressed: () async {
                      await _getAttributes(
                        attributes: (grouped) async =>
                            await context.openAddVariant(groupedAttrs: grouped),
                      );
                    },
                  )
                : _buildCard(context, results),
          SetupError<Attribute>(error: final error) => context.buildError(
            error,
          ),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<Attribute> categories) {
    return DynamicDataTable(
      omitAtIndex: 0,
      headers: Attribute.dataHeader,
      toolbar: _buildToolbar(categories),
      rows: categories.map((cat) => cat.itemAsList).toList(),
      onEditTap: (row) async => _onEditTap(categories, row.first),
      onDeleteTap: (row) async => _onDeleteTap(categories, row.first),
    );
  }

  _buildToolbar(List<Attribute> attributes) {
    return ListToolbarButtons(
      primaryLabel: 'Add Variant',
      refreshLabel: 'Refresh Variants',
      dataLength: attributes.length,
      onPrimary: () async {
        await _getAttributes(
          attributes: (grouped) async =>
              await context.openAddVariant(groupedAttrs: grouped),
        );
      },
      onRefresh: () =>
          context.read<AttributeBloc>().add(RefreshSetups<Attribute>()),
    );
  }

  Future<void> _onEditTap(List<Attribute> attributes, String id) async {
    final attribute = Attribute.findAttributesById(attributes, id).first;
    await context.openAddVariant(serverVariant: attribute);
  }

  Future<void> _onDeleteTap(List<Attribute> attributes, String id) async {
    final attribute = Attribute.findAttributesById(attributes, id).first;

    final isConfirmed = await context.confirmUserActionDialog();
    if (mounted && isConfirmed) {
      /// Delete specific Attribute
      context.read<AttributeBloc>().add(
        DeleteSetup<String>(documentId: attribute.id),
      );
    }
  }
}
