import 'dart:async';

import 'package:assign_erp/core/constants/app_constant.dart';
import 'package:assign_erp/features/auth/presentation/screen/sign_in/workspace_sign_in_screen.dart';
import 'package:assign_erp/features/onboarding/onboarding_screen.dart';
import 'package:assign_erp/features/startup/splash_screen.dart';
import 'package:assign_erp/features/trouble_shooting/data/data_sources/local/device_info_cache.dart';
import 'package:flutter/material.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  Timer? _timer;
  bool _hideSplashScreen = false;
  final _deviceInfoCache = DeviceInfoCache();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  /// Start a timer to trigger the dialog after a delay
  void _startTimer() {
    _timer = Timer(kRProgressDelay, () {
      setState(() => _hideSplashScreen = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _hideSplashScreen ? _determineInitialRoute() : const SplashScreen();
  }

  _determineInitialRoute() {
    bool hideOnboarding = _deviceInfoCache.hideOnboarding;

    return hideOnboarding ? WorkspaceSignInScreen() : OnBoardingScreen();
  }
}
