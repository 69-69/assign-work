import 'dart:io';

import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/core/widgets/screen_helper.dart';
import 'package:assign_erp/features/setup/data/models/company_info_model.dart';
import 'package:assign_erp/features/setup/presentation/bloc/company/company_bloc.dart';
import 'package:assign_erp/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:assign_erp/features/setup/presentation/screen/company/add/add_company_info.dart';
import 'package:assign_erp/features/setup/presentation/screen/company/update/update_company_info.dart';
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
      body: _buildCard(context),
      floatingActionButton: context.buildFloatingBtn(
        '${info.isEmpty ? 'setup' : 'edit'} company',
        onPressed: () => info.isEmpty
            ? context.openAddCompanyInfo()
            : context.openUpdateCompanyInfo(info: info),
        icon: info.isEmpty ? Icons.add : Icons.edit,
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildLogo(context),
              const SizedBox(height: 20),
              Text(
                info.name.toTitle,
                textAlign: TextAlign.start,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.displaySmall?.copyWith(
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 20.0),
              _buildRichText(
                context,
                label: 'Address / Location',
                text: info.address,
              ),
              _buildRichText(context, label: 'Phone', text: info.phone),
              _buildRichText(context, label: 'Alt Phone', text: info.altPhone),
              _buildRichText(context, label: 'Fax', text: info.faxNumber),
              _buildRichText(context, label: 'Email', text: info.email),
            ],
          ),
        ),
      ],
    );
  }

  _buildLogo(BuildContext context) {
    var wh = context.screenWidth * 0.07;

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
                  width: wh,
                  semanticLabel: 'logo',
                )
              : SizedBox(
                  width: 100,
                  height: 100,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => info.isEmpty
                        ? context.openAddCompanyInfo()
                        : context.openUpdateCompanyInfo(info: info),
                    icon: const Placeholder(
                      color: kDangerColor,
                      child: Center(child: Text('Logo here')),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildRichText(
    BuildContext context, {
    String label = '',
    String text = '',
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: RichText(
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          text: '$label: ',
          style: context.textTheme.titleLarge?.copyWith(color: kTextColor),
          children: [
            TextSpan(
              text: text.toTitle,
              style: context.textTheme.titleLarge?.copyWith(
                color: kDarkTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
