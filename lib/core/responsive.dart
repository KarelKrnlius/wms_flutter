import 'package:flutter/material.dart';

/// Breakpoint aplikasi native WMS.
///
/// Mobile dan desktop sengaja memiliki pola navigasi berbeda. Tablet menjadi
/// jembatan dengan navigation rail agar ruang horizontal tidak terbuang.
abstract final class AppBreakpoints {
  static const double tablet = 720;
  static const double desktop = 1100;
  static const double maxContentWidth = 1540;
}

enum AppFormFactor { mobile, tablet, desktop }

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  AppFormFactor get formFactor {
    if (screenWidth >= AppBreakpoints.desktop) return AppFormFactor.desktop;
    if (screenWidth >= AppBreakpoints.tablet) return AppFormFactor.tablet;
    return AppFormFactor.mobile;
  }

  bool get isMobile => formFactor == AppFormFactor.mobile;
  bool get isTablet => formFactor == AppFormFactor.tablet;
  bool get isDesktop => formFactor == AppFormFactor.desktop;

  EdgeInsets get pagePadding => switch (formFactor) {
    AppFormFactor.mobile => const EdgeInsets.all(16),
    AppFormFactor.tablet => const EdgeInsets.all(24),
    AppFormFactor.desktop => const EdgeInsets.fromLTRB(32, 24, 32, 32),
  };
}

class AdaptiveContent extends StatelessWidget {
  const AdaptiveContent({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}
