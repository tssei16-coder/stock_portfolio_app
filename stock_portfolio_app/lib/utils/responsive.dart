import 'package:flutter/material.dart';

/// レスポンシブブレークポイント
const double kMobileBreakpoint = 600;
const double kTabletBreakpoint = 900;
const double kDesktopBreakpoint = 1200;

enum ScreenSize { mobile, tablet, desktop }

ScreenSize getScreenSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < kMobileBreakpoint) return ScreenSize.mobile;
  if (width < kTabletBreakpoint) return ScreenSize.tablet;
  return ScreenSize.desktop;
}

bool isMobile(BuildContext context) =>
    MediaQuery.of(context).size.width < kMobileBreakpoint;

bool isTablet(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  return w >= kMobileBreakpoint && w < kTabletBreakpoint;
}

bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= kTabletBreakpoint;

/// レスポンシブウィジェット切り替えヘルパー
class ResponsiveBuilder extends StatelessWidget {
  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kTabletBreakpoint) return desktop;
        if (constraints.maxWidth >= kMobileBreakpoint) {
          return tablet ?? desktop;
        }
        return mobile;
      },
    );
  }
}
