/// The Aura brand, as `aura.pen` declares it.
abstract final class AuraBrand {
  /// The product name, from the pen's `brand-name` variable.
  ///
  /// A proper noun and the wordmark on the splash screen, so it is deliberately
  /// not localized and has no ARB key: it reads `Aura` in every locale, the way
  /// a logo does. The pen declares it as a variable beside the colours and the
  /// fonts, which is what makes this a token rather than copy.
  static const String name = 'Aura';
}
