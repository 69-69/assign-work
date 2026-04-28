import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/util/url_launcher_util.dart';
import 'package:assign_erp/core/widgets/neumorphism.dart';
import 'package:assign_erp/features/app_training/data/models/user_guide_model.dart';
import 'package:assign_erp/features/app_training/presentation/screen/how_to_config_app/create/create_app_training.dart';
import 'package:flutter/material.dart';

class GuideCard extends StatefulWidget {
  final List<AppTraining> guides;
  final bool isEdit;

  const GuideCard({super.key, required this.guides, required this.isEdit});

  @override
  State<GuideCard> createState() => _GuideCardState();
}

class _GuideCardState extends State<GuideCard> {
  late double maxCrossAxisExtent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMaxCrossAxisExtent();
  }

  void _updateMaxCrossAxisExtent() {
    // context.isMobile ? screenW :
    var screenW = context.screenWidth;
    maxCrossAxisExtent = (context.isPortraitMode ? screenW / 2 : screenW / 4);
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }

  GridView _buildBody(BuildContext context) {
    return GridView.builder(
      primary: false,
      itemCount: widget.guides.length,
      physics: const RangeMaintainingScrollPhysics(),
      padding: EdgeInsets.all(20),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        // mainAxisExtent: maxCrossAxisExtent,
        // Spacing between rows
        mainAxisSpacing: 20,
        // Spacing between columns
        crossAxisSpacing: 20,
        // Ratio between the width and height of grid items
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final guide = widget.guides[index];
        final bgColor = randomBgColors[index];
        return _CardContent(
          guide: guide,
          isEdit: widget.isEdit,
          bgColor: bgColor,
        );
      },
    );
  }
}

class _CardContent extends StatelessWidget {
  final AppTraining guide;
  final Color bgColor;
  final bool isEdit;

  const _CardContent({
    required this.guide,
    required this.bgColor,
    required this.isEdit,
  });

  TextStyle get _titleStyle => const TextStyle(
    overflow: TextOverflow.ellipsis,
    color: Color.fromRGBO(255, 255, 255, 0.9),
  );

  @override
  Widget build(BuildContext context) {
    return Wrap(
      direction: Axis.vertical,
      runAlignment: WrapAlignment.center,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Guide', style: _titleStyle),
        if (!context.isMiniMobile) ...[_buildTitle(context)],
        _buildButton(context),
        if (!context.isMobile) ...[_buildTextButton()],
      ],
    ).fluidGlassMorphism(bgColor: bgColor, addBorder: false);
  }

  Widget _buildTitle(BuildContext context) => Text(
    guide.title.toTitle,
    style: _titleStyle.copyWith(fontWeight: FontWeight.bold),
    textScaler: TextScaler.linear(context.textScaleFactor),
  );

  Widget _buildButton(BuildContext context) =>
      isEdit ? _buildEditButton(context) : _buildPlayButton(context);

  Widget _buildEditButton(BuildContext context) => _buildActionButton(
    context,
    icon: Icons.edit_note,
    tooltip: 'Edit ${guide.title} guide',
    onPressed: () async => await context.openCreateTraining(serverGuide: guide),
  );

  Widget _buildPlayButton(BuildContext context) => _buildActionButton(
    context,
    tooltip: guide.description,
    onPressed: () async => await _launchUrl(),
  );

  Widget _buildTextButton() => TextButton.icon(
    onPressed: () async => await _launchUrl(),
    label: Text('Watch Video', style: _titleStyle.copyWith(color: kWhiteColor)),
    icon: const Icon(Icons.link_outlined, color: kWhiteColor),
    style: TextButton.styleFrom(
      backgroundColor: kModelColor.toAlpha(0.1),
      textStyle: _titleStyle.copyWith(color: kWhiteColor),
    ),
  );

  Widget _buildActionButton(
    BuildContext context, {
    IconData? icon,
    String? tooltip,
    required void Function() onPressed,
  }) => IconButton(
    onPressed: onPressed,
    tooltip: tooltip ?? guide.description,
    icon: Icon(icon ?? Icons.play_circle_outline),
    iconSize: context.screenWidth * 0.08,
    color: kDangerColor,
  );

  _launchUrl() async =>
      await UrlLaunchUtil.urlLauncher(url: guide.url, inApp: true);
}
