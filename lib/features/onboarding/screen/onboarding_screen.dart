import 'dart:async';

import 'package:assign_erp/config/routes/route_names.dart';
import 'package:assign_erp/core/constants/app_colors.dart';
import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/core/network/data_sources/local/index.dart';
import 'package:assign_erp/core/widgets/dialog/prompt_user_for_action.dart';
import 'package:assign_erp/core/widgets/layout/custom_scaffold.dart';
import 'package:assign_erp/features/auth/presentation/screen/widget/master_reset.dart';
import 'package:assign_erp/features/onboarding/data/onboarding_data.dart';
import 'package:assign_erp/features/onboarding/screen/onboarding_content_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen>
    with SingleTickerProviderStateMixin {
  final _deviceInfoCache = DeviceInfoCache();
  late PageController _pageController;
  late Timer _autoPageTimer;
  int _currentPage = 0;
  List<OnBoardingModel> get _boards => OnBoardingData.boards;

  void _startAutoPageTimer() {
    _autoPageTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_currentPage < _boards.length - 1) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: kDProgressDelay,
          curve: Curves.easeInOutCubic,
        );
      } else {
        timer.cancel();
        final routePath = context.routeFromUri;

        // Only show Dialog in initial/onBoarding screen
        if (routePath == RouteNames.initialScreen ||
            routePath.contains(RouteNames.initialScreenName)) {
          final isContinue = await context.confirmAction<bool>(
            const Text('Initial onboarding complete. Continue to sign in?'),
            title: 'Proceed to Sign In',
            onAccept: 'Continue',
            onReject: 'Cancel',
          );

          if (isContinue) {
            await _goToWorkspaceSignIn();
          }
        }
      }
    });
  }

  void _resetAutoTimer() {
    _autoPageTimer.cancel();
    _startAutoPageTimer();
  }

  /// When the next button is pressed if we are on first page
  /// we will go to second page, otherwise we will go to login page
  Future<void> _onNextButtonPressed() async {
    _resetAutoTimer(); // Reset auto-timer when user interacts

    if (_currentPage + 1 == _boards.length) {
      await _goToWorkspaceSignIn();
    } else {
      int newPage = _currentPage + 1;
      _pageController.animateToPage(
        newPage,
        duration: kDProgressDelay,
        curve: Curves.easeInOutCubic,
      );
    }
    setState(() {});
  }

  // Navigate to the given route & then remove all the previous routes
  Future<void> _goToWorkspaceSignIn() async {
    await _deviceInfoCache.setOnboarding();
    if (!mounted) return;
    context.goNamed(RouteNames.workspaceSignIn);
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (mounted) {
      _startAutoPageTimer();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoPageTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      isGradientBg: true,

      /// Next button is inside [OnBoardingContentView] widget
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return [buildAppBar(context)];
        },
        body: Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _buildBody(),
        ),
      ),
      actions: [],
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Row _buildBottomNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(
          child: Tooltip(
            message: 'Sign in to Workspace',
            child: TextButton(
              onPressed: () async => await _goToWorkspaceSignIn(),
              child: const Text(
                'Workspace Sign In',
                semanticsLabel: 'Workspace Sign In',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Tooltip(
            message: 'Contact Support Team',
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Need Help?',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),

        /// Long Press to Reset/Logout from all Sessions
        MasterResetButton(),
      ],
    );
  }

  SliverAppBar buildAppBar(BuildContext context) {
    return SliverAppBar(
      snap: true,
      pinned: true,
      floating: true,
      leading: Tooltip(
        message: 'Skip Onboarding',
        child: TextButton(
          key: const Key("skipOnBoarding"),
          onPressed: () async => await _goToWorkspaceSignIn(),
          child: Text(
            'Skip',
            semanticsLabel: 'Skip',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: kLightBlueColor,
            ),
          ),
        ),
      ),
      title: _buildAppBarTitle(context),
      actions: [buildAppbarActions()],
      backgroundColor: kTransparentColor,
    );
  }

  Tooltip buildAppbarActions() {
    return Tooltip(
      message: 'Continue to Next Page',
      child: TextButton(
        key: const Key("nextOnBoarding"),
        onPressed: () async => await _onNextButtonPressed(),
        child: Text(
          'Next',
          semanticsLabel: 'Next',
          style: TextStyle(fontWeight: FontWeight.bold, color: kLightBlueColor),
        ),
      ),
    );
  }

  Padding _buildAppBarTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active Page
          Text(
            '${_currentPage + 1}',
            semanticsLabel: '${_currentPage + 1}',
            style: context.textTheme.bodyLarge?.copyWith(
              color: kLightBlueColor,
            ),
          ),
          // Total Pages
          Text(
            '/${_boards.length}',
            semanticsLabel: '${_boards.length}',
            style: context.textTheme.bodyLarge?.copyWith(color: kGrayBlueColor),
          ),
        ],
      ),
    );
  }

  Column _buildBody() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        /// Image
        Expanded(child: _pageViewBuilder()),
      ],
    );
  }

  PageView _pageViewBuilder() {
    return PageView.builder(
      itemBuilder: (context, index) {
        final board = _boards[index];
        return OnBoardingContentView(
          board: board,
          currentIndex: index,
          onPressedNext: () async => await _onNextButtonPressed(),
        );
      },
      onPageChanged: (v) {
        _currentPage = v;
        _resetAutoTimer(); // reset timer on swipe
        setState(() {});
      },
      controller: _pageController,
      itemCount: _boards.length,
    );
  }
}

/*
  PageView _pageViewCustom() {
    return PageView.custom(
      controller: _pageController,
      childrenDelegate: SliverChildBuilderDelegate((context, index) {
        return Transform.scale(
          scale: index == currentPage ? 1.0 : 0.9,
          child: OnBoardingContentView(
            board: _boards[index],
            currentIndex: index,
            onPressedNext: _onNextButtonPressed,
          ),
        );
      }, childCount: _boards.length),
      onPageChanged: (index) {
        setState(() {
          currentPage = index;
        });
      },
    );
  }*/
