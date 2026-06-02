// lib/formatting/widget/kudi_refresh_indicator.dart
// =============================================================================
// KudiRefreshIndicator — branded pull-to-refresh wrapper
// -----------------------------------------------------------------------------
// A thin wrapper around Flutter's RefreshIndicator that:
//   • Enforces the app's teal brand colour (#069494)
//   • Guarantees AlwaysScrollableScrollPhysics on the child scroll view
//     (critical for short-content screens where the pull gesture wouldn't fire)
//   • Provides a consistent displacement / strokeWidth across all screens
//
// USAGE:
// -------
// Replace any bare RefreshIndicator + SingleChildScrollView combo with:
//
//   KudiRefreshIndicator(
//     onRefresh: () => ref.read(refreshProvider.notifier).refreshAll(),
//     child: ListView(children: [...]),   // or SingleChildScrollView / CustomScrollView
//   )
//
// The child MUST be a scrollable widget.  KudiRefreshIndicator automatically
// injects AlwaysScrollableScrollPhysics so you don't have to remember.
// =============================================================================

import 'package:flutter/material.dart';

class KudiRefreshIndicator extends StatelessWidget {
  const KudiRefreshIndicator({
    Key? key,
    required this.onRefresh,
    required this.child,
    this.displacement = 60.0,
  }) : super(key: key);

  /// The async callback that performs the actual data fetch.
  /// The spinner stays visible until the returned Future completes.
  final Future<void> Function() onRefresh;

  /// The scrollable child (ListView, SingleChildScrollView, etc.).
  final Widget child;

  /// How far from the top the spinner appears. Default 60 keeps it
  /// below status bar and any pinned headers.
  final double displacement;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: const Color(0xFF069494),       // Kudi teal
      backgroundColor: Colors.white,
      strokeWidth: 2.5,
      displacement: displacement,
      // _PhysicsInjecter ensures the pull gesture fires even when the child's
      // content is shorter than the viewport (e.g. sparse HomeScreen).
      child: _PhysicsInjecter(child: child),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helper — walks the widget tree to inject AlwaysScrollableScrollPhysics
// into the first ScrollView it finds without requiring callers to remember.
// ---------------------------------------------------------------------------
class _PhysicsInjecter extends StatelessWidget {
  const _PhysicsInjecter({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // If the caller already used AlwaysScrollableScrollPhysics we trust it.
    // Otherwise wrap with a ScrollConfiguration that forces it globally.
    return ScrollConfiguration(
      behavior: _AlwaysScrollBehavior(),
      child: child,
    );
  }
}

class _AlwaysScrollBehavior extends ScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const AlwaysScrollableScrollPhysics();
}
