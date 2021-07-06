import 'package:flutter/material.dart';

import 'acrylic_win32.dart';

/// Acrylic effects.
enum AcrylicEffect {
  /// Default window background. No blur effect.
  disabled,

  /// Solid window background.
  solid,

  /// Transparent window background.
  transparent,

  /// Aero blur effect. Windows Vista & Windows 7 like.
  aero,

  /// Acrylic blur effect. Requires Windows 10 version 1803 or higher.
  acrylic
}

late final AcrylicWin32 acrylic;

/// **Acrylic**
///
/// _Example_
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   Acrylic.initialize();
///   runApp(MyApp());
/// }
///
/// ...
/// Acrylic.setEffect(
///   effect: AcrylicEffect.aero,
///   gradientColor: Colors.white.withOpacity(0.2)
/// );
/// ```
///
class Acrylic {
  /// Initializes [Acrylic] class.
  ///
  /// Must be called before calling [Acrylic.setEffect].
  ///
  /// _Example_
  /// ```dart
  /// Acrylic.initialize();
  /// ```
  ///
  static void initialize({bool drawCustomFrame = false}) {
    acrylic = AcrylicWin32();
  }

  static int convertAcrylicEffect(AcrylicEffect effect) {
    switch (effect) {
      case AcrylicEffect.disabled:
        return ACCENT_STATE.ACCENT_DISABLED;
      case AcrylicEffect.solid:
        return ACCENT_STATE.ACCENT_ENABLE_GRADIENT;
      case AcrylicEffect.transparent:
        return ACCENT_STATE.ACCENT_ENABLE_TRANSPARENTGRADIENT;
      case AcrylicEffect.aero:
        return ACCENT_STATE.ACCENT_ENABLE_BLURBEHIND;
      case AcrylicEffect.acrylic:
      default:
        return ACCENT_STATE.ACCENT_ENABLE_ACRYLICBLURBEHIND;
    }
  }

  /// Sets [BlurEffect] for the window.
  ///
  /// Uses undocumented `SetWindowCompositionAttribute` API from `user32.dll` on Windows.
  ///
  /// Enables aero, acrylic or other transparency on the Flutter instance window.
  ///
  /// _Example_
  /// ```dart
  /// FlutterAcrylic.setEffect(
  ///   effect: AcrylicEffect.acrylic,
  ///   gradientColor: Colors.black.withOpacity(0.2)
  /// );
  /// ```
  ///
  static void setEffect(
      {required AcrylicEffect effect, Color gradientColor = Colors.white}) {
    final state = convertAcrylicEffect(effect);
    acrylic.setEffect(gradientColor.red, gradientColor.green,
        gradientColor.blue, gradientColor.alpha, state);
  }
}
