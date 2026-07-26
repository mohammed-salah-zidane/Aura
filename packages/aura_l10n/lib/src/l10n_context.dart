import 'package:aura_l10n/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Reaches Aura's copy from a widget.
extension AuraL10n on BuildContext {
  /// Every user-visible string in the app, in the active locale.
  ///
  /// Non-nullable: the delegate is installed at the root, so a screen that can
  /// build at all has copy available.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
