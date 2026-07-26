import 'dart:ui';

/// A gradient defined by its stops, as authored in `aura.pen`.
///
/// Kept independent of `LinearGradient` so tokens stay usable in painters and
/// in shaders, not only in decorations.
class AuraGradient {
  /// Creates a gradient token.
  const AuraGradient({required this.colors, required this.stops});

  /// Stop colours, in order.
  final List<Color> colors;

  /// Stop positions from 0 to 1, matching [colors] by index.
  final List<double> stops;
}

/// The condition skies. In Aura the background *is* the weather, so every
/// condition swaps the whole-screen gradient.
///
/// Stops are the designed positions from each screen frame, not evenly spaced.
abstract final class AuraSkies {
  /// Clear day. Warms towards the horizon.
  static const AuraGradient clearDay = AuraGradient(
    colors: <Color>[
      Color(0xFF0E3C7A),
      Color(0xFF295F9F),
      Color(0xFF5589B8),
      Color(0xFF9C9482),
      Color(0xFFE4AE5C),
    ],
    stops: <double>[0, 0.36, 0.6, 0.8, 1],
  );

  /// Partly cloudy.
  static const AuraGradient partlyCloudy = AuraGradient(
    colors: <Color>[
      Color(0xFF2C6BAA),
      Color(0xFF4E86BC),
      Color(0xFF6E97B4),
      Color(0xFF88A6B8),
    ],
    stops: <double>[0, 0.45, 0.78, 1],
  );

  /// Overcast.
  static const AuraGradient overcast = AuraGradient(
    colors: <Color>[
      Color(0xFF3B4956),
      Color(0xFF4E5E6C),
      Color(0xFF65747F),
    ],
    stops: <double>[0, 0.5, 1],
  );

  /// Rain.
  static const AuraGradient rain = AuraGradient(
    colors: <Color>[
      Color(0xFF1E2A34),
      Color(0xFF2F4456),
      Color(0xFF486074),
    ],
    stops: <double>[0, 0.55, 1],
  );

  /// Thunderstorm.
  static const AuraGradient thunderstorm = AuraGradient(
    colors: <Color>[
      Color(0xFF141620),
      Color(0xFF242840),
      Color(0xFF3A3050),
    ],
    stops: <double>[0, 0.5, 1],
  );

  /// Snow.
  static const AuraGradient snow = AuraGradient(
    colors: <Color>[
      Color(0xFF3E5A72),
      Color(0xFF557A93),
      Color(0xFF6E8CA0),
    ],
    stops: <double>[0, 0.55, 1],
  );

  /// Clear night. Carries a starfield on top.
  static const AuraGradient clearNight = AuraGradient(
    colors: <Color>[
      Color(0xFF090D26),
      Color(0xFF141C40),
      Color(0xFF22305C),
    ],
    stops: <double>[0, 0.5, 1],
  );

  /// Fog.
  static const AuraGradient fog = AuraGradient(
    colors: <Color>[
      Color(0xFF4E585F),
      Color(0xFF616B72),
      Color(0xFF7B858C),
    ],
    stops: <double>[0, 0.5, 1],
  );

  /// Brand sky. Used by search, settings, saved cities and the state screens,
  /// where no single condition owns the screen.
  static const AuraGradient systemBrand = AuraGradient(
    colors: <Color>[
      Color(0xFF0E3C7A),
      Color(0xFF1E568F),
      Color(0xFF2A6A9E),
    ],
    stops: <double>[0, 0.55, 1],
  );

  /// Dark instrument dashboard.
  static const AuraGradient instrument = AuraGradient(
    colors: <Color>[
      Color(0xFF141A21),
      Color(0xFF0E1319),
      Color(0xFF0A0D11),
    ],
    stops: <double>[0, 0.5, 1],
  );

  /// Splash. Deeper than the brand sky so the mark's glow reads.
  static const AuraGradient splash = AuraGradient(
    colors: <Color>[
      Color(0xFF0B1630),
      Color(0xFF14284C),
      Color(0xFF243E63),
      Color(0xFF3A4E6E),
    ],
    stops: <double>[0, 0.45, 0.8, 1],
  );

  /// Weather alert detail. Warm at the top to signal heat.
  static const AuraGradient weatherAlert = AuraGradient(
    colors: <Color>[
      Color(0xFF3A2A22),
      Color(0xFF2A3E63),
      Color(0xFF24507E),
    ],
    stops: <double>[0, 0.5, 1],
  );

  /// Sun and moon detail.
  static const AuraGradient sunAndMoon = AuraGradient(
    colors: <Color>[
      Color(0xFF0A1330),
      Color(0xFF182450),
      Color(0xFF28386B),
    ],
    stops: <double>[0, 0.5, 1],
  );
}

/// Gradients used inside components rather than as a screen background.
abstract final class AuraGradients {
  /// UV index scale bar. Four bands.
  static const AuraGradient uvScale = AuraGradient(
    colors: <Color>[
      Color(0xFF5CD97E),
      Color(0xFFF4CE3B),
      Color(0xFFF5883A),
      Color(0xFFEF4B4B),
    ],
    stops: <double>[0, 0.45, 0.72, 1],
  );

  /// Air-quality scale bar. Five bands, matching the EPA index range.
  static const AuraGradient aqiScale = AuraGradient(
    colors: <Color>[
      Color(0xFF5CD97E),
      Color(0xFFF4CE3B),
      Color(0xFFF5883A),
      Color(0xFFEF4B4B),
      Color(0xFFA970C9),
    ],
    stops: <double>[0, 0.33, 0.5, 0.7, 1],
  );

  /// Cold-to-hot segment of a forecast temperature range bar.
  static const AuraGradient temperatureRange = AuraGradient(
    colors: <Color>[Color(0xFF86B7E8), Color(0xFFF4C56A)],
    stops: <double>[0, 1],
  );

  /// Sweep used by loading skeletons.
  static const AuraGradient skeletonShimmer = AuraGradient(
    colors: <Color>[
      Color(0x10FFFFFF),
      Color(0x1FFFFFFF),
      Color(0x10FFFFFF),
    ],
    stops: <double>[0, 0.5, 1],
  );

  /// Outer glow of the Aura mark. Radial.
  static const AuraGradient markGlow = AuraGradient(
    colors: <Color>[Color(0x55FFD68A), Color(0x00FFD68A)],
    stops: <double>[0, 0.72],
  );

  /// Core of the Aura mark. Radial.
  static const AuraGradient markCore = AuraGradient(
    colors: <Color>[
      Color(0xFFFFF7E0),
      Color(0xFFFBC66A),
      Color(0xFFEF9E30),
    ],
    stops: <double>[0, 0.55, 1],
  );

  /// Glow around the sun on the sun-path arc. Radial.
  static const AuraGradient sunGlow = AuraGradient(
    colors: <Color>[Color(0x88FFD68A), Color(0x00FFD68A)],
    stops: <double>[0, 0.72],
  );

  /// Sun body on the sun-path arc. Radial.
  static const AuraGradient sunCore = AuraGradient(
    colors: <Color>[
      Color(0xFFFFF7E0),
      Color(0xFFFBC66A),
      Color(0xFFEF9E30),
    ],
    stops: <double>[0, 0.6, 1],
  );

  /// Glow around the moon phase disc. Radial.
  static const AuraGradient moonGlow = AuraGradient(
    colors: <Color>[Color(0x40C9D2F0), Color(0x00C9D2F0)],
    stops: <double>[0, 0.72],
  );

  /// Lit face of the moon phase disc. Radial.
  static const AuraGradient moonLit = AuraGradient(
    colors: <Color>[Color(0xFFEEF1FB), Color(0xFFC3CBE6)],
    stops: <double>[0, 1],
  );
}
