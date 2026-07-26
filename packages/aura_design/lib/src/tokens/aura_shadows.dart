import 'package:flutter/painting.dart';

/// Elevation tokens. Values are read from `aura.pen`.
///
/// Aura uses outer drop shadows only. Blur separates the two elevation levels,
/// and alpha separates the standard sky surfaces from the deeper instrument
/// surfaces.
abstract final class AuraShadows {
  /// Tile elevation. Metric cards, hour cells, list rows.
  static const List<BoxShadow> tile = <BoxShadow>[
    BoxShadow(
      color: Color(0x5508213F),
      offset: Offset(0, 8),
      blurRadius: 22,
      spreadRadius: -6,
    ),
  ];

  /// Tile elevation on a darker sky.
  static const List<BoxShadow> tileStrong = <BoxShadow>[
    BoxShadow(
      color: Color(0x660A1E38),
      offset: Offset(0, 8),
      blurRadius: 22,
      spreadRadius: -6,
    ),
  ];

  /// Panel elevation. Full-width sections and sheets.
  static const List<BoxShadow> panel = <BoxShadow>[
    BoxShadow(
      color: Color(0x5508213F),
      offset: Offset(0, 10),
      blurRadius: 30,
      spreadRadius: -8,
    ),
  ];

  /// Panel elevation on a darker sky.
  static const List<BoxShadow> panelStrong = <BoxShadow>[
    BoxShadow(
      color: Color(0x6608213F),
      offset: Offset(0, 10),
      blurRadius: 30,
      spreadRadius: -6,
    ),
  ];

  /// Panel elevation at the deepest tint, for a panel over a bright horizon.
  static const List<BoxShadow> panelDeep = <BoxShadow>[
    BoxShadow(
      color: Color(0x8808213F),
      offset: Offset(0, 10),
      blurRadius: 30,
      spreadRadius: -8,
    ),
  ];

  /// Panel elevation on the instrument surface, where the shadow is neutral
  /// rather than blue.
  static const List<BoxShadow> panelNeutral = <BoxShadow>[
    BoxShadow(
      color: Color(0x55000000),
      offset: Offset(0, 10),
      blurRadius: 30,
      spreadRadius: -8,
    ),
  ];
}
