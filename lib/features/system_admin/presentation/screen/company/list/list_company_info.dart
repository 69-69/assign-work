import 'dart:io';

import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/address_info_model.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/layout/form_group_card.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/system_admin/data/models/company_model.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/company/company_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/create/create_company_info.dart';
import 'package:assign_erp/features/system_admin/presentation/screen/company/update/update_company_info.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListCompanyInfo extends StatelessWidget {
  const ListCompanyInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CompanyBloc>(
      create: (context) =>
          CompanyBloc(firestore: FirebaseFirestore.instance)
            ..add(GetSetups<Company>()),
      child: _buildBody(),
    );
  }

  BlocBuilder<CompanyBloc, SetupState<Company>> _buildBody() {
    return BlocBuilder<CompanyBloc, SetupState<Company>>(
      builder: (context, state) {
        return switch (state) {
          LoadingSetup<Company>() => context.loader,
          SetupsLoaded<Company>(data: var results) =>
            results.isEmpty
                ? context.buildAddButton(
                    'Setup Company',
                    onPressed: () => context.openAddCompanyInfo(),
                  )
                : _InfoCard(info: results.first),
          SetupError<Company>(error: final error) => context.buildError(error),
          _ => const SizedBox.shrink(),
        };
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Company info;

  const _InfoCard({required this.info});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      noAppBar: true,
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: _buildBody(context),
      ),
      bottomNavigationBar: const SizedBox.shrink(),
    );
  }

  EdgeInsets get _contentPadding => EdgeInsets.fromLTRB(40, 10, 40, 10);

  Widget _buildBody(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildCompanyInfo(context),
        ),
      ],
    );
  }

  Widget _buildCompanyInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormGroupCard(
          contentPadding: _contentPadding,
          children: [
            if (info.isNotEmpty) _buildEditButton(context),
            Row(
              children: [
                _buildLogo(context),
                const SizedBox(width: 16.0),
                Expanded(child: _buildCompanyDetails(context)),
              ],
            ),
          ],
        ),
        ...info.addresses.map((e) => _buildAddressInfo(context, e: e)),
      ],
    );
  }

  Widget _buildAddressInfo(BuildContext context, {required AddressInfo e}) {
    final pad = const EdgeInsets.only(top: 8.0);
    return FormGroupCard(
      title: '${e.type.getName} Address'.toUpperAll,
      scrollDirection: Axis.vertical,
      contentPadding: _contentPadding,
      children: [
        _buildRichText(context, label: 'Street', text: e.street, padding: pad),
        _buildRichText(context, label: 'City', text: e.city, padding: pad),
        _buildRichText(
          context,
          label: 'Postal Code',
          text: e.postalCode,
          padding: pad,
        ),
        _buildRichText(
          context,
          label: 'State / Region',
          text: e.state,
          padding: pad,
        ),
      ],
    );
  }

  Widget _buildCompanyDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTitleText(context, info.name.toTitle),
        _buildRichText(
          context,
          label: 'Phone',
          text: '${info.phone} / ${info.altPhone}',
        ),
        _buildRichText(context, label: 'Email', text: info.email),
        _buildRichText(context, label: 'Fax', text: info.faxNumber),
      ],
    );
  }

  Widget _buildTitleText(BuildContext context, String text) {
    return Text(
      text,
      textAlign: TextAlign.start,
      overflow: TextOverflow.ellipsis,
      style: context.textTheme.titleLarge?.copyWith(
        color: context.onSurfaceColor,
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    final color = context.onPrimaryContainer;

    return Align(
      alignment: Alignment.topRight,
      child: context.outlinedIconBtn(
        Icon(Icons.edit, color: color),
        label: 'Edit Company',
        txtColor: color,
        borderColor: color,
        onPressed: () => context.openUpdateCompanyInfo(serverInfo: info),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    var logoSize = context.screenWidth * 0.09;
    var isComLogo =
        info.logo != null &&
        info.logo!.isNotEmpty &&
        File(info.logo!).existsSync();

    return Card(
      elevation: 5,
      color: kWhiteColor,
      margin: const EdgeInsets.only(top: 18.0),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: isComLogo
              ? Image.file(
                  File(info.logo!),
                  fit: BoxFit.cover,
                  width: logoSize,
                  semanticLabel: 'logo',
                )
              : _buildLogoPlaceholder(context),
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: IconButton(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () => info.isEmpty
            ? context.openAddCompanyInfo()
            : context.openUpdateCompanyInfo(serverInfo: info),
        icon: const Placeholder(
          color: kDangerColor,
          child: Center(child: Text('Logo here')),
        ),
      ),
    );
  }

  Widget _buildRichText(
    BuildContext context, {
    String label = '',
    String text = '',
    EdgeInsetsGeometry? padding,
  }) {
    final style = context.textTheme.bodyLarge;

    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 4.0),
      child: RichText(
        overflow: TextOverflow.fade,
        softWrap: true,
        text: TextSpan(
          text: '$label: ',
          style: style?.copyWith(color: kTextColor),
          children: [
            TextSpan(
              text: text.toTitle,
              style: style?.copyWith(color: context.onSurfaceColor),
            ),
          ],
        ),
      ),
    );
  }
}
