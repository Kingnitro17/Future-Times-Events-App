import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Renders [materialChild] on Android, [cupertinoChild] on iOS.
/// If only [child] is provided, renders it on both platforms.
class AdaptiveWrapper extends StatelessWidget {
  const AdaptiveWrapper({
    super.key,
    this.child,
    this.materialChild,
    this.cupertinoChild,
  }) : assert(
          child != null || (materialChild != null && cupertinoChild != null),
          'Provide either child OR both materialChild and cupertinoChild.',
        );

  final Widget? child;
  final Widget? materialChild;
  final Widget? cupertinoChild;

  static bool get isIOS => defaultTargetPlatform == TargetPlatform.iOS;
  static bool get isAndroid => defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    if (child != null) return child!;
    return isIOS ? cupertinoChild! : materialChild!;
  }
}

/// Adaptive scroll view — uses [CustomScrollView] with either
/// [CupertinoSliverNavigationBar] or [SliverAppBar].
class AdaptiveSliverScaffold extends StatelessWidget {
  const AdaptiveSliverScaffold({
    super.key,
    required this.title,
    required this.slivers,
    this.actions,
    this.largeTitle = true,
    this.backgroundColor,
    this.onRefresh,
  });

  final String title;
  final List<Widget> slivers;
  final List<Widget>? actions;
  final bool largeTitle;
  final Color? backgroundColor;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    if (AdaptiveWrapper.isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: backgroundColor,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverNavigationBar(
              largeTitle: Text(title),
              trailing: actions != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    )
                  : null,
              backgroundColor:
                  backgroundColor ?? CupertinoColors.systemBackground,
            ),
            if (onRefresh != null)
              CupertinoSliverRefreshControl(onRefresh: onRefresh),
            ...slivers,
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(title),
            actions: actions,
            pinned: true,
            expandedHeight: largeTitle ? 120 : null,
          ),
          if (onRefresh != null)
            SliverList(
              delegate: SliverChildListDelegate([
                RefreshIndicator(
                  onRefresh: onRefresh!,
                  child: const SizedBox.shrink(),
                ),
              ]),
            ),
          ...slivers,
        ],
      ),
    );
  }
}
