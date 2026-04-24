import 'package:assign_erp/core/widgets/button/list_toolbar_buttons.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/layout/dynamic_data_table.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/master_data/attribute_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/master_data/attribute_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/master_data/variants_master/create/create_attributes.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AttributeValues extends StatefulWidget {
  const AttributeValues({super.key});

  @override
  State<AttributeValues> createState() => _AttributeValuesState();
}

class _AttributeValuesState extends State<AttributeValues> {
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
                    'Create Attribute',
                    onPressed: () => context.openAddAttribute(),
                  )
                : _buildCard(context, results),
          SetupError<Attribute>(error: final error) => context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildCard(BuildContext c, List<Attribute> attributes) {
    return DynamicDataTable(
      omitAtIndex: 0,
      headers: Attribute.dataHeader,
      toolbar: _buildToolbar(attributes),
      rows: attributes.map((cat) => cat.itemAsList).toList(),
      onEditTap: (row) async => _onEditTap(attributes, row.first),
      onDeleteTap: (row) async => _onDeleteTap(attributes, row.first),
    );
  }

  _buildToolbar(List<Attribute> attributes) {
    return ListToolbarButtons(
      primaryLabel: 'Add Attribute',
      refreshLabel: 'Refresh Attributes',
      dataLength: attributes.length,
      onPrimary: () => context.openAddAttribute(),
      onRefresh: () =>
          context.read<AttributeBloc>().add(RefreshSetups<Attribute>()),
    );
  }

  Future<void> _onEditTap(List<Attribute> attributes, String id) async {
    final attribute = Attribute.findAttributesById(attributes, id).first;
    await context.openAddAttribute(serverAttribute: attribute);
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
