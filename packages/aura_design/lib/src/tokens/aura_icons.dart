import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Every icon the design uses, and nothing else.
///
/// The design is Lucide-only. Material icons are never substituted: if a glyph
/// is missing here, add it from the design rather than reaching for
/// `Icons.*` at a call site.
abstract final class AuraIcons {
  // ------------------------------------------------------------- conditions

  /// Clear day.
  static const IconData sun = LucideIcons.sun;

  /// Sun behind cloud.
  static const IconData cloudSun = LucideIcons.cloudSun;

  /// Overcast.
  static const IconData cloud = LucideIcons.cloud;

  /// Rain.
  static const IconData cloudRain = LucideIcons.cloudRain;

  /// Light rain.
  static const IconData cloudDrizzle = LucideIcons.cloudDrizzle;

  /// Thunderstorm.
  static const IconData cloudLightning = LucideIcons.cloudLightning;

  /// Snow.
  static const IconData cloudSnow = LucideIcons.cloudSnow;

  /// Snowflake, used for the snow metric.
  static const IconData snowflake = LucideIcons.snowflake;

  /// Fog.
  static const IconData cloudFog = LucideIcons.cloudFog;

  /// Clear night.
  static const IconData moon = LucideIcons.moon;

  /// Cloudy night.
  static const IconData cloudMoon = LucideIcons.cloudMoon;

  /// Clear night with stars.
  static const IconData moonStar = LucideIcons.moonStar;

  /// Lightning, used on the alert banner.
  static const IconData zap = LucideIcons.zap;

  // ------------------------------------------------------------------ astro

  /// Sunrise.
  static const IconData sunrise = LucideIcons.sunrise;

  /// Sunset.
  static const IconData sunset = LucideIcons.sunset;

  // ---------------------------------------------------------------- metrics

  /// Feels-like temperature.
  static const IconData thermometer = LucideIcons.thermometer;

  /// Wind speed and direction.
  static const IconData wind = LucideIcons.wind;

  /// Humidity.
  static const IconData droplets = LucideIcons.droplets;

  /// Pressure.
  static const IconData gauge = LucideIcons.gauge;

  /// Visibility.
  static const IconData eye = LucideIcons.eye;

  /// Rain probability.
  static const IconData umbrella = LucideIcons.umbrella;

  /// Compass heading.
  static const IconData navigation = LucideIcons.navigation;

  // --------------------------------------------------------------------- ui

  /// Search.
  static const IconData search = LucideIcons.search;

  /// Settings.
  static const IconData settings = LucideIcons.settings;

  /// Saved cities list.
  static const IconData list = LucideIcons.list;

  /// Current location pin.
  static const IconData mapPin = LucideIcons.mapPin;

  /// Locate me.
  static const IconData locateFixed = LucideIcons.locateFixed;

  /// Refresh.
  static const IconData refresh = LucideIcons.refreshCw;

  /// Forward chevron.
  static const IconData chevronRight = LucideIcons.chevronRight;

  /// Back chevron.
  static const IconData chevronLeft = LucideIcons.chevronLeft;

  /// Dismiss.
  static const IconData close = LucideIcons.x;

  /// Empty a field. Ringed, unlike the bare dismiss cross.
  static const IconData clear = LucideIcons.circleX;

  /// Overflow menu.
  static const IconData more = LucideIcons.ellipsisVertical;

  /// Favourite.
  static const IconData star = LucideIcons.star;

  /// Loading spinner.
  static const IconData loader = LucideIcons.loaderCircle;

  // ------------------------------------------------------------------ state

  /// Warning, used on the alert banner and the alert detail.
  static const IconData alert = LucideIcons.triangleAlert;

  /// Informational note.
  static const IconData info = LucideIcons.info;

  /// Success.
  static const IconData success = LucideIcons.circleCheck;

  /// Failure.
  static const IconData failure = LucideIcons.circleX;

  /// Offline.
  static const IconData offline = LucideIcons.cloudOff;

  /// Cached data source.
  static const IconData cached = LucideIcons.database;

  /// Last updated.
  static const IconData history = LucideIcons.history;

  /// Forecast period.
  static const IconData calendarClock = LucideIcons.calendarClock;

  // ------------------------------------------------------------- status bar

  /// Cellular signal.
  static const IconData cellular = LucideIcons.signalHigh;

  /// Wi-Fi.
  static const IconData wifi = LucideIcons.wifi;

  /// Battery.
  static const IconData battery = LucideIcons.batteryFull;
}
