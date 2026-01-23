import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/util/str_util.dart';
import 'package:assign_erp/core/widgets/developer_info.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:flutter/material.dart';

const subTitle =
    'A.I\nP.O.S\nC.R.M\nReports\nInventory\nWarehouse\nMulti-Location\nMobile & Desktop\nWeb-Cloud\n...';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late double maxCrossAxisExtent;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateMaxCrossAxisExtent();
  }

  void _updateMaxCrossAxisExtent() {
    var screenW = context.screenWidth;
    maxCrossAxisExtent = context.isMiniMobile
        ? screenW
        : (context.isPortraitMode ? screenW / 2 : screenW / 3);
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      isGradientBg: true,
      backButton: const SizedBox.shrink(),
      // bgColor: context.ofTheme.primaryColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: _buildBody(context)),
          const DeveloperInfo(textColor: kPrimaryColor),
        ],
      ),
      actions: [],
      bottomNavigationBar: const SizedBox.shrink(),
      floatingActionButton: const SizedBox.shrink(),
    );
  }

  Widget _buildBody(BuildContext context) {
    return GridView.builder(
      primary: false,
      itemCount: context.isPortraitMode ? 9 : 6,
      physics: const RangeMaintainingScrollPhysics(),
      padding: context.isMobile
          ? const EdgeInsets.symmetric(vertical: 5)
          : const EdgeInsets.all(30),
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
        final randomBgColor = randomBgColors[index % randomBgColors.length];
        return index.isOdd
            ? _buildStack(context, randomBgColor)
            : _buildCard(context, randomBgColor);
      },
    );
  }

  _buildCard(BuildContext context, Color randomBgColor) {
    // final borderSide = BorderSide(width: 4, color: randomBgColor);

    return AnimatedContainer(
      decoration: BoxDecoration(
        color: randomBgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      padding: const EdgeInsets.all(20.0),
      duration: kAnimateDuration,
      child: GridTile(
        child: Center(
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            titleAlignment: ListTileTitleAlignment.center,
            title: Text(
              appName.split('.').first.toUpperAll,
              textAlign: TextAlign.center,
              style: context.textTheme.titleLarge?.copyWith(
                color: kPrimaryColor,
                overflow: TextOverflow.ellipsis,
                fontWeight: FontWeight.bold,
              ),
              textScaler: TextScaler.linear(context.textScaleFactor),
            ),
            subtitle: Text(
              subTitle,
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                color: kLightBlueColor,
                overflow: TextOverflow.ellipsis,
              ),
              textScaler: TextScaler.linear(context.textScaleFactor),
            ),
          ),
        ),
      ),
    );
  }

  Stack _buildStack(BuildContext context, Color randomBgColor) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Image.asset(
          appLogo,
          fit: BoxFit.scaleDown,
          width: context.screenWidth * 0.2,
          semanticLabel: appName,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Wrap(
            runSpacing: 4,
            alignment: WrapAlignment.center,
            runAlignment: WrapAlignment.center,
            children: [
              const Text(
                "Getting $appName Ready...",
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: kPrimaryColor),
              ),
              _buildDefaultProgressIndicator(randomBgColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultProgressIndicator(Color randomBgColor) {
    return LinearProgressIndicator(
      semanticsLabel: 'loading',
      minHeight: 8,
      backgroundColor: kLightBlueColor,
      valueColor: AlwaysStoppedAnimation<Color>(randomBgColor),
    );
  }
}
