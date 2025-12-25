import 'dart:io';

import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/network/data_sources/models/address_model.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/horizontal_divider.dart';
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
        padding: const EdgeInsets.all(50),
        child: _buildBody(context),
      ),
      bottomNavigationBar: const SizedBox.shrink(),
    );
  }

  Widget _buildBody(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: FormGroupCard(
            children: [
              if (info.isNotEmpty) _buildEditButton(context),
              _buildCompanyInfo(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLogo(context),
            const SizedBox(width: 16.0),
            _buildCompanyDetails(context),
          ],
        ),
        HorizontalDivider(),
        ...info.addresses.map(
          (e) => _buildRichText(
            context,
            label: '${e.type.getName} Address'.toTitle,
            text: e.address,
            padding: const EdgeInsets.only(top: 10.0),
          ),
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
    return Container(
      padding: const EdgeInsets.only(right: 6.0),
      alignment: Alignment.centerRight,
      child: context.outlinedIconBtn(
        Icon(Icons.edit, color: kPrimaryAccentColor),
        label: 'Edit Company',
        txtColor: kPrimaryAccentColor,
        borderColor: kPrimaryAccentColor,
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
    return Padding(
      padding: padding ?? const EdgeInsets.only(top: 4.0),
      child: RichText(
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          text: '$label: ',
          style: context.textTheme.titleLarge?.copyWith(color: kTextColor),
          children: [
            TextSpan(
              text: text.toTitle,
              style: context.textTheme.titleLarge?.copyWith(
                color: context.onSurfaceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
