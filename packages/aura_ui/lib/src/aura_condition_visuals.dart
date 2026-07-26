import 'package:aura_design/aura_design.dart';
import 'package:aura_domain/aura_domain.dart';
import 'package:flutter/widgets.dart';

/// What a weather condition looks like.
///
/// `aura_design` may not import the domain, and `aura_domain` may not import
/// Flutter, so the table joining them lives here. Every value on the right is a
/// design token; every value on the left is a condition the domain derived from
/// `condition.code`.
abstract final class AuraConditionVisuals {
  /// The sky a condition paints.
  ///
  /// A code the domain does not know falls back to the brand sky, which is the
  /// one no condition owns, rather than to a guess at a neighbouring one.
  static AuraSkyKind sky(AuraCondition condition) => switch (condition) {
    AuraCondition.clearDay => AuraSkyKind.clearDay,
    AuraCondition.clearNight => AuraSkyKind.clearNight,
    AuraCondition.partlyCloudy => AuraSkyKind.partlyCloudy,
    AuraCondition.overcast => AuraSkyKind.overcast,
    AuraCondition.fog => AuraSkyKind.fog,
    AuraCondition.rain => AuraSkyKind.rain,
    AuraCondition.snow => AuraSkyKind.snow,
    AuraCondition.thunderstorm => AuraSkyKind.thunderstorm,
    AuraCondition.unknown => AuraSkyKind.systemBrand,
  };

  /// The Lucide glyph a condition is drawn with.
  static IconData icon(AuraCondition condition) => switch (condition) {
    AuraCondition.clearDay => AuraIcons.sun,
    AuraCondition.clearNight => AuraIcons.moon,
    AuraCondition.partlyCloudy => AuraIcons.cloudSun,
    AuraCondition.overcast => AuraIcons.cloud,
    AuraCondition.fog => AuraIcons.cloudFog,
    AuraCondition.rain => AuraIcons.cloudRain,
    AuraCondition.snow => AuraIcons.cloudSnow,
    AuraCondition.thunderstorm => AuraIcons.cloudLightning,
    AuraCondition.unknown => AuraIcons.cloud,
  };

  /// The tint that glyph carries.
  static Color tint(AuraCondition condition) => switch (condition) {
    AuraCondition.clearDay => AuraColors.conditionSun,
    AuraCondition.clearNight => AuraColors.conditionMoon,
    AuraCondition.partlyCloudy => AuraColors.conditionCloudSun,
    AuraCondition.overcast => AuraColors.conditionCloud,
    AuraCondition.fog => AuraColors.conditionCloudFog,
    AuraCondition.rain => AuraColors.conditionCloudRain,
    AuraCondition.snow => AuraColors.conditionCloudSnow,
    AuraCondition.thunderstorm => AuraColors.conditionCloudLightning,
    AuraCondition.unknown => AuraColors.conditionCloud,
  };

  /// The glyph for an hour, which swaps to a sunset when the sun goes down
  /// during it.
  ///
  /// The pen draws the hour the sun sets with a sunset glyph rather than the
  /// condition's own, which is the one place an hour cell departs from the
  /// table above.
  static IconData hourIcon(
    AuraCondition condition, {
    required bool isSunset,
  }) => isSunset ? AuraIcons.sunset : icon(condition);

  /// The tint for [hourIcon].
  static Color hourTint(AuraCondition condition, {required bool isSunset}) =>
      isSunset ? AuraColors.conditionSunset : tint(condition);
}
