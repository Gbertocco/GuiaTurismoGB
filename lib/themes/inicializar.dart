import 'package:flutter/material.dart';
import 'package:guia_turismo/controllers/theme_controller.dart';
import 'package:guia_turismo/screens/home_screen.dart';
import 'package:provider/provider.dart';

class Inicializar extends StatelessWidget {
  const Inicializar({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, controllerTema, child) =>
        MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: 'home',
      theme: controllerTema.temaClaro(),
      darkTheme: controllerTema.temaEscuro(),
      themeMode: controllerTema.temaAtual,
      routes: {
        'home':(context) => HomeScreen(),
        // 'login' (context) => LoginScreen()
      }
    )
        )
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