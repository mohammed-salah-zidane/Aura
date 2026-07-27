/// Presentation shared by every Aura feature.
///
/// Two jobs, both of which sit exactly on the seam between the domain and the
/// design system, and neither of which either package may own: turning a
/// domain value into the copy a screen shows for it, and turning a weather
/// condition into the sky, glyph and tint that stand for it.
library;

export 'src/aura_condition_visuals.dart';
export 'src/aura_failure_copy.dart';
export 'src/aura_format.dart';
export 'src/aura_sky_body.dart';
