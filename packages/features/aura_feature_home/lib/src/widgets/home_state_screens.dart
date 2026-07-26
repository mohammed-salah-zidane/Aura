import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:aura_ui/aura_ui.dart';
import 'package:flutter/widgets.dart';

/// The screen when there is nothing to show, and why.
class HomeFailure extends StatelessWidget {
  /// Creates the failure screen.
  const HomeFailure({
    required this.failure,
    required this.onTryAgain,
    super.key,
  });

  /// What went wrong.
  final AppFailure failure;

  /// Asks the service again.
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final copy = AuraFailureCopy.of(l10n, failure);
    return AuraStateScreen(
      icon: copy.icon,
      iconColor: AuraColors.textSecondary,
      title: copy.title,
      body: copy.body,
      actions: <Widget>[
        AuraButtonPrimary(
          label: l10n.offlineTryAgain,
          icon: AuraIcons.refresh,
          onPressed: onTryAgain,
        ),
      ],
    );
  }
}

/// The screen when the service is out of reach but a reading is stored.
///
/// The note says how old the reading is and what it says, so the choice
/// between waiting and reading it is an informed one.
class HomeOffline extends StatelessWidget {
  /// Creates the offline screen.
  const HomeOffline({
    required this.age,
    required this.placeName,
    required this.temperature,
    required this.onTryAgain,
    required this.onUseStoredReading,
    super.key,
  });

  /// How old the stored reading is, already worded.
  final String age;

  /// The place it is for.
  final String placeName;

  /// What it says the temperature was, already worded.
  final String temperature;

  /// Asks the service again.
  final VoidCallback onTryAgain;

  /// Shows the stored reading instead.
  final VoidCallback onUseStoredReading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AuraStateScreen(
      icon: AuraIcons.offline,
      iconColor: AuraColors.textSecondary,
      title: l10n.offlineTitle,
      body: l10n.offlineBody,
      note: AuraStateNote(
        icon: AuraIcons.history,
        label: l10n.offlineNote(
          l10n.homeLastUpdated(age),
          placeName,
          temperature,
        ),
      ),
      actions: <Widget>[
        AuraButtonPrimary(
          label: l10n.offlineTryAgain,
          icon: AuraIcons.refresh,
          onPressed: onTryAgain,
        ),
        AuraButtonSecondary(
          label: l10n.offlineUseSavedData,
          onPressed: onUseStoredReading,
        ),
      ],
    );
  }
}
