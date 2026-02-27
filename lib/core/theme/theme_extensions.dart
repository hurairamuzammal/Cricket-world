import 'package:flutter/material.dart';

/// Carries app-wide theme flags that widgets can react to without directly
/// depending on the theme service.
class CricketThemeSettings extends ThemeExtension<CricketThemeSettings> {
  final bool isMonochrome;

  const CricketThemeSettings({required this.isMonochrome});

  @override
  CricketThemeSettings copyWith({bool? isMonochrome}) {
    return CricketThemeSettings(
      isMonochrome: isMonochrome ?? this.isMonochrome,
    );
  }

  @override
  CricketThemeSettings lerp(
    ThemeExtension<CricketThemeSettings>? other,
    double t,
  ) {
    if (other is! CricketThemeSettings) {
      return this;
    }
    return CricketThemeSettings(
      isMonochrome: t < 0.5 ? isMonochrome : other.isMonochrome,
    );
  }
}

extension CricketThemeSettingsX on BuildContext {
  bool get isMonochromeTheme =>
      Theme.of(this).extension<CricketThemeSettings>()?.isMonochrome ?? false;
}
