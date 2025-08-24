import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/util/size_config.dart';
import 'package:assign_erp/core/widgets/button/custom_button.dart';
import 'package:assign_erp/core/widgets/delayed_animation.dart';
import 'package:assign_erp/features/onboarding/data/onboarding_data.dart';
import 'package:flutter/material.dart';

const int delayedAmount = 500;

const _onBoardingButtonColors = [
  kDarkWarningColor,
  kBrightPrimaryColor,
  Color(0xFF4F82C9),
  kLightOrangeColor,
  Color(0xFF5E9FEE),
];

class OnBoardingContentView extends StatelessWidget {
  const OnBoardingContentView({
    super.key,
    required this.board,
    required this.currentIndex,
    required this.onPressedNext,
  });

  final OnBoardingModel board;
  final int currentIndex;
  final void Function() onPressedNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildImage(),

        /// Title, Subtitle, Button
        _buildTitle(context.ofTheme),
        if (context.isMobile && context.isLandscapeMode)
          ...[]
        else ...[
          DelayedAnimation(
            delay: delayedAmount + 2000,
            child: buildNextButton(context),
          ),
        ],
      ],
    );
  }

  _buildImage() {
    return Expanded(child: Image.asset(board.imageLink, fit: BoxFit.contain));
  }

  SizedBox buildNextButton(BuildContext context) {
    return SizedBox(
      width: context.screenWidth * 0.5,
      child: context.elevatedIconBtn(
        Row(
          children: List.generate(
            currentIndex + 1,
            (index) => Icon(
              Icons.adaptive.arrow_forward,
              color: currentIndex == index ? kLightColor : kLightBlueColor,
              size: 13,
            ),
          ),
        ),
        onPressed: onPressedNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: _onBoardingButtonColors[currentIndex],
          padding: const EdgeInsets.all(10),
          // shape: const StadiumBorder(),
        ),
        iconAlignment: IconAlignment.end,
        label: Text('Next', style: TextStyle(color: kLightColor)),
      ),
    );
  }

  _buildTitle(ThemeData customTheme) {
    return Column(
      children: [
        DelayedAnimation(
          delay: delayedAmount + 500,
          child: Text(
            board.title,
            style: customTheme.textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.w500,
              color: kPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        DelayedAnimation(
          delay: delayedAmount + 1000,
          child: Text(
            board.subtitle,
            style: customTheme.textTheme.bodyLarge?.copyWith(
              color: kPrimaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        // Button
      ],
    );
  }
}
