import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../analytics/analytics.dart';
import '../analytics/analytics_pages.dart';
import '../assets/tokens/token_extensions.dart';
import '../base/error_screen.dart';
import '../ping/utils/lifecycle_widget.dart';
import '../shared/architecture/view_model.dart';
import '../shared/rate_limiters/throttle.dart';
import 'delayed_cancellable_loader.dart';
import 'screen_background.dart';

// Required for adding the background to top level page view widgets
class ScreenWrapper extends StatelessWidget {
  final AnalyticsPage analyticsPageName;
  final bool hasBottomSafeArea;
  final Widget? footer;
  final Widget Function(BuildContext) builder;
  final String? backgroundImage;
  final ViewModel? viewModel;
  final Widget? topMenu;
  final Future<void> Function()? onRefresh;
  final bool? hasRoundedTop;
  final VoidCallback? onAppear;
  final VoidCallback? onDismiss;
  final bool? bypassTextScaleFactorLock;
  final Color? backgroundColor;
  final bool includeMargin;

  const ScreenWrapper({
    required this.builder,
    required this.analyticsPageName,
    super.key,
    this.topMenu,
    this.backgroundImage,
    this.viewModel,
    this.hasBottomSafeArea = true,
    this.footer,
    this.onRefresh,
    this.hasRoundedTop,
    this.onAppear,
    this.onDismiss,
    this.bypassTextScaleFactorLock = false,
    this.backgroundColor,
    this.includeMargin = false,
  });

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: (bypassTextScaleFactorLock ?? false)
            ? MediaQuery.of(context).textScaler
            : const TextScaler.linear(1),
      ),
      child: LifecycleWidget(
        onAppear: () {
          onAppear?.call();
          final Map<String, dynamic>? eventProperties =
              viewModel?.pageViewEventProperties();

          analytics.logPageView(
            analyticsPageName,
            eventProperties:
                (eventProperties?.isNotEmpty ?? false) ? eventProperties : null,
          );
        },
        onDisappear: () {
          onDismiss?.call();
        },
        viewModel: viewModel,
        child: PullToRefresh(
          onRefresh: viewModel?.onRefresh?.call ?? onRefresh,
          throttleKey: analyticsPageName.toString(),
          child: ShowCaseWidget(
            builder: Builder(
              builder: (_) {
                return ChildInSafeArea(
                  backgroundImage: backgroundImage,
                  backgroundColor: backgroundColor,
                  analyticsPageName: analyticsPageName,
                  viewModel: viewModel,
                  hasBottomSafeArea: hasBottomSafeArea,
                  topMenu: topMenu,
                  builder: builder,
                  footer: footer,
                  hasRoundedTop: hasRoundedTop,
                  includeMargin: includeMargin,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class PullToRefresh extends StatelessWidget {
  final Future<void> Function()? onRefresh;
  final String? throttleKey;
  final Widget child;

  const PullToRefresh({
    required this.child,
    super.key,
    this.onRefresh,
    this.throttleKey,
  });

  @override
  Widget build(BuildContext context) {
    return onRefresh != null
        ? RefreshIndicator(
            onRefresh: () async {
              final throttleRefresh = Throttler.asyncSimpleThrottle(
                duration: const Duration(seconds: 30),
                future: onRefresh!,
                throttleKey: throttleKey ?? '',
              );
              return await throttleRefresh();
            },
            color: context.color.accentOnSecondaryDefault,
            backgroundColor: context.color.accentSecondaryDefault,
            strokeWidth: 3.0,
            child: child,
          )
        : child;
  }
}

class ChildInSafeArea extends StatelessWidget {
  final bool hasBottomSafeArea;
  final String? backgroundImage;
  final Widget Function(BuildContext)? builder;
  final AnalyticsPage analyticsPageName;
  final ViewModel? viewModel;
  final Widget? footer;
  final Widget? topMenu;
  final bool? hasRoundedTop;
  final Color? backgroundColor;
  final bool includeMargin;

  const ChildInSafeArea({
    required this.hasBottomSafeArea,
    required this.analyticsPageName,
    required this.topMenu,
    required this.builder,
    super.key,
    this.hasRoundedTop,
    this.backgroundImage,
    this.footer,
    this.viewModel,
    this.backgroundColor,
    this.includeMargin = false,
  });

  @override
  Widget build(BuildContext context) {
    final viewState = viewModel?.viewState;

    if (viewState != null && viewState == ViewState.loading) {
      return ScreenBackground(
        hasRoundedTop: hasRoundedTop,
        backgroundImage: backgroundImage,
        backgroundColor: backgroundColor,
        child: SafeArea(
          bottom: hasBottomSafeArea,
          top: false,
          child: viewState == ViewState.error
              ? const ErrorScreen()
              : SafeArea(
                  child: DelayedCancellableLoader(topMenu: topMenu),
                ),
        ),
      );
    }

    // Rlly uses a footer instead of the bottom safe area
    final useBottomSafeArea = footer == null && hasBottomSafeArea;

    return ScreenBackground(
      hasRoundedTop: hasRoundedTop,
      backgroundImage: backgroundImage,
      backgroundColor: backgroundColor,
      includeMargin: includeMargin,
      child: SafeArea(
        bottom: useBottomSafeArea,
        top: false,
        child: footer != null
            // This column prevents shrink-wrapping to content size
            ? Column(
                children: [
                  Expanded(child: Builder(builder: builder!)),
                  if (footer != null) footer!,
                ],
              )
            : Builder(builder: builder!),
      ),
    );
  }
}
