
import 'package:flutter/material.dart';

AppBarTheme defineAppBar(cor){
  return AppBarTheme(
    centerTitle: true,
    backgroundColor: cor.primary,
    foregroundColor: cor.onPrimary,
    elevation: 4,
  );
}

BottomNavigationBarThemeData defineNavegacaoBase (cor){
  return BottomNavigationBarThemeData(
    backgroundColor: cor.primary,
    elevation: 4,

  );
}

ElevatedButtonThemeData defineBotaoElevated(cor){
  return ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom()
  );
}