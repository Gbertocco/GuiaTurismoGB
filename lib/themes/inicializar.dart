import 'package:flutter/material.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/controllers/theme_controller.dart';
import 'package:guia_turismo/screens/cadastro_lugar_sreeen.dart';
import 'package:guia_turismo/screens/home_screen.dart';
import 'package:guia_turismo/screens/mapa_screen.dart';
import 'package:provider/provider.dart';

class Inicializar extends StatelessWidget {
  const Inicializar({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeController()),
        ChangeNotifierProvider(create: (context) => LugaresController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, controllerTema, child) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Guia Turismo GB',
          initialRoute: 'home',
          theme: controllerTema.temaClaro(),
          darkTheme: controllerTema.temaEscuro(),
          themeMode: controllerTema.temaAtual,
          routes: {
            'home': (context) => HomeScreen(),
            'cadastro_lugar': (context) => const CadastroLugarScreen(),
            'mapa': (context) => const MapaScreen(),
            // 'login' (context) => LoginScreen()
          },
        ),
      ),
    );
  }
}

//MaterialApp(
// debugShowCheckedModeBanner: false,
//  initialRoute: 'home',
//  theme: ,
//  routes: {
//    'home':(context) => HomeScreen(),
//     // 'login' (context) => LoginScreen()
//   }
// );
