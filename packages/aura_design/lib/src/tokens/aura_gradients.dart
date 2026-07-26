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

/// The radial wash a sky paints over its linear gradient.
///
/// Every frame in `aura.pen` carries exactly two fills: a vertical linear
/// gradient, and this bloom above it. Reading only the first one drops the
/// light source out of every screen in the app.
///
/// The pen's `size` is the ellipse **diameter** as a fraction of the frame, so
/// the semi-axes are half of each factor. `center` is a fraction of the frame
/// and defaults to the middle on either axis.
class AuraBloom {
  /// Creates a bloom token.
  const AuraBloom({
    required this.colors,
    required this.stops,
    required this.opacity,
    required this.widthFactor,
    required this.heightFactor,
    this.centerX = 0.5,
    this.centerY = 0.5,
  });

  /// Stop colours, from the centre outward.
  final List<Color> colors;

  /// Stop positions from 0 to 1, matching [colors] by index.
  final List<double> stops;

  /// Opacity of the whole fill layer, applied on top of each stop's own alpha.
  final double opacity;

  /// Ellipse width as a fraction of the frame width.
  final double widthFactor;

  /// Ellipse height as a fraction of the frame height.
  final double heightFactor;

  /// Horizontal centre as a fraction of the frame width.
  final double centerX;

  /// Vertical centre as a fraction of the frame height.
  final double centerY;
}

/// The bloom of each sky, read from the second fill of its frame.
///
/// Every bloom in the design has exactly two stops, transparent at the outer
/// one, which is what lets the sky transition interpolate them pairwise.
abstract final class AuraBlooms {
  /// Clear day. A warm haze low on the horizon.
  static const AuraBloom clearDay = AuraBloom(
    colors: <Color>[Color(0xC7FFF4D5), Color(0x00FFF4D5)],
    stops: <double>[0, 1],
    opacity: 0.9,
    widthFactor: 1.3,
    heightFactor: 0.58,
    centerY: 0.19,
  );

  /// Partly cloudy.
  static const AuraBloom partlyCloudy = AuraBloom(
    colors: <Color>[Color(0x99FFFFFF), Color(0x00FFFFFF)],
    stops: <double>[0, 1],
    opacity: 0.6,
    widthFactor: 1.3,
    heightFactor: 0.55,
    centerY: 0.2,
  );

  /// Overcast. The flattest light in the set.
  static const AuraBloom overcast = AuraBloom(
    colors: <Color>[Color(0x66C9D3DB), Color(0x00C9D3DB)],
    stops: <double>[0, 1],
    opacity: 0.32,
    widthFactor: 1.3,
    heightFactor: 0.5,
    centerY: 0.18,
  );

  /// Rain.
  static const AuraBloom rain = AuraBloom(
    colors: <Color>[Color(0x667FA6C2), Color(0x007FA6C2)],
    stops: <double>[0, 1],
    opacity: 0.3,
    widthFactor: 1.3,
    heightFactor: 0.55,
    centerY: 0.2,
  );

  /// Thunderstorm.
  static const AuraBloom thunderstorm = AuraBloom(
    colors: <Color>[Color(0x806E5A9E), Color(0x006E5A9E)],
    stops: <double>[0, 1],
    opacity: 0.5,
    widthFactor: 1.3,
    heightFactor: 0.5,
    centerY: 0.16,
  );

  /// Snow.
  static const AuraBloom snow = AuraBloom(
    colors: <Color>[Color(0x77EAF2F8), Color(0x00EAF2F8)],
    stops: <double>[0, 1],
    opacity: 0.5,
    widthFactor: 1.3,
    heightFactor: 0.55,
    centerY: 0.2,
  );

  /// Clear night. Sits off to the right, unlike every other sky.
  static const AuraBloom clearNight = AuraBloom(
    colors: <Color>[Color(0x66AEB8E0), Color(0x00AEB8E0)],
    stops: <double>[0, 1],
    opacity: 0.7,
    widthFactor: 1.1,
    heightFactor: 0.45,
    centerX: 0.68,
    centerY: 0.15,
  );

  /// Fog. The lowest and widest bloom, which is what reads as haze.
  static const AuraBloom fog = AuraBloom(
    colors: <Color>[Color(0x88C3CBD0), Color(0x00C3CBD0)],
    stops: <double>[0, 1],
    opacity: 0.5,
    widthFactor: 1.3,
    heightFactor: 0.6,
    centerY: 0.3,
  );

  /// Brand sky.
  static const AuraBloom systemBrand = AuraBloom(
    colors: <Color>[Color(0x40FFFFFF), Color(0x00FFFFFF)],
    stops: <double>[0, 1],
    opacity: 0.5,
    widthFactor: 1.2,
    heightFactor: 0.5,
    centerY: 0.12,
  );

  /// Dark instrument dashboard.
  static const AuraBloom instrument = AuraBloom(
    colors: <Color>[Color(0x402A4A7A), Color(0x002A4A7A)],
    stops: <double>[0, 1],
    opacity: 0.5,
    widthFactor: 1,
    heightFactor: 0.5,
    centerX: 0.2,
    centerY: 0,
  );

  /// Splash. The only bloom that goes transparent before the ellipse edge, and
  /// the only one centred near the middle of the screen, behind the mark.
  static const AuraBloom splash = AuraBloom(
    colors: <Color>[Color(0x4DFFD68A), Color(0x00FFD68A)],
    stops: <double>[0, 0.75],
    opacity: 0.95,
    widthFactor: 1.2,
    heightFactor: 0.7,
    centerY: 0.42,
  );

  /// Weather alert detail.
  static const AuraBloom weatherAlert = AuraBloom(
    colors: <Color>[Color(0x3DFF8A5B), Color(0x00FF8A5B)],
    stops: <double>[0, 1],
    opacity: 0.5,
    widthFactor: 1.2,
    heightFactor: 0.45,
    centerY: 0.1,
  );

  /// Sun and moon detail. Offset right, like the clear-night sky.
  static const AuraBloom sunAndMoon = AuraBloom(
    colors: <Color>[Color(0x40AEB8E0), Color(0x00AEB8E0)],
    stops: <double>[0, 1],
    opacity: 0.6,
    widthFactor: 1,
    heightFactor: 0.4,
    centerX: 0.7,
    centerY: 0.12,
  );
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
