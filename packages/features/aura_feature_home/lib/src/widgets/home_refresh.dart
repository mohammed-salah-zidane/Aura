import 'package:flutter/material.dart'
    show RefreshIndicator, RefreshIndicatorStatus;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Pull to refresh, without the stock spinner.
///
/// The gesture is still Flutter's, so the pull behaves the way it does in
/// every other app on each platform. What it draws is not a disc at the top:
/// the sun now owns that band of sky, so the in-flight signal is the Aura mark
/// breathing beside the page dots in the bottom bar, where the eye already
/// goes for state.
///
/// A tick fires the moment the pull arms, which is the point the gesture
/// commits. That is the only haptic on this screen that is not tied to a tap.
class HomeRefresh extends StatelessWidget {
  /// Wraps [child] in the refresh gesture.
  const HomeRefresh({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  /// Runs the fetch. The gesture ends when this completes.
  final Future<void> Function() onRefresh;

  /// The scrollable being pulled.
  final Widget child;

  void _onStatusChange(RefreshIndicatorStatus? status) {
    if (status == RefreshIndicatorStatus.armed) {
      HapticFeedback.mediumImpact().ignore();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator.noSpinner(
      onRefresh: onRefresh,
      onStatusChange: _onStatusChange,
      child: child,
    );
  }
}
