import 'package:flutter/material.dart';

AppBarTheme defineAppBar(ColorScheme cor) {
  return AppBarTheme(
    centerTitle: true,
    backgroundColor: cor.primary,
    foregroundColor: cor.onPrimary,
    elevation: 4,
  );
}

BottomNavigationBarThemeData defineNavegacaoBase(ColorScheme cor) {
  return BottomNavigationBarThemeData(
    backgroundColor: cor.primary,
    elevation: 4,
  );
}

ElevatedButtonThemeData defineBotaoElevated(ColorScheme cor) {
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: cor.primary,
      foregroundColor: cor.onPrimary,
    ),
  );
}
