import 'package:aura_core/aura_core.dart';
import 'package:aura_design/aura_design.dart';
import 'package:aura_l10n/aura_l10n.dart';
import 'package:flutter/widgets.dart';

/// How a failure is put to the user.
///
/// Every screen that can fail says the same thing about the same failure, so
/// the table lives once rather than once per screen. The recovery action is
/// each screen's own: home offers a retry, search leaves the field open.
@immutable
final class AuraFailureCopy {
  /// Creates a description.
  const AuraFailureCopy({
    required this.icon,
    required this.title,
    required this.body,
  });

  /// Reads the description of [failure] in the active locale.
  factory AuraFailureCopy.of(AppLocalizations l10n, AppFailure failure) =>
      switch (failure) {
        NoConnection() => AuraFailureCopy(
          icon: AuraIcons.offline,
          title: l10n.offlineTitle,
          body: l10n.offlineBody,
        ),
        Timeout() => AuraFailureCopy(
          icon: AuraIcons.history,
          title: l10n.failureTimeoutTitle,
          body: l10n.failureTimeoutBody,
        ),
        InvalidCity() => AuraFailureCopy(
          icon: AuraIcons.mapPin,
          title: l10n.failureInvalidCityTitle,
          body: l10n.failureInvalidCityBody,
        ),
        Unauthorized() => AuraFailureCopy(
          icon: AuraIcons.failure,
          title: l10n.failureUnauthorizedTitle,
          body: l10n.failureUnauthorizedBody,
        ),
        RateLimited() => AuraFailureCopy(
          icon: AuraIcons.failure,
          title: l10n.failureRateLimitedTitle,
          body: l10n.failureRateLimitedBody,
        ),
        ServerError() => AuraFailureCopy(
          icon: AuraIcons.failure,
          title: l10n.failureServerTitle,
          body: l10n.failureServerBody,
        ),
        // The repository answers a miss with the network failure that caused
        // the lookup, so a cache miss only reaches a screen if that changes.
        CacheMiss() || Unknown() => AuraFailureCopy(
          icon: AuraIcons.failure,
          title: l10n.failureUnknownTitle,
          body: l10n.failureUnknownBody,
        ),
      };

  /// Glyph for the state screen's disc.
  final IconData icon;

  /// What happened, in a few words.
  final String title;

  /// Why, and what the user can do about it.
  final String body;
}
