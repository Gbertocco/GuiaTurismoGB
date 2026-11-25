import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:guia_turismo/controllers/gps_controller.dart';
import 'package:guia_turismo/controllers/lugares_controller.dart';
import 'package:guia_turismo/controllers/theme_controller.dart';
import 'package:guia_turismo/screens/cadastro_lugar_sreeen.dart';
import 'package:guia_turismo/screens/home_screen.dart';
import 'package:guia_turismo/screens/login_screen.dart';
import 'package:guia_turismo/screens/lugares_screen.dart';
import 'package:guia_turismo/screens/mapa_screen.dart';

class Inicializar extends StatefulWidget {
  const Inicializar({super.key});
  @override
  State<Inicializar> createState() => _InicializarState();
}

class _InicializarState extends State<Inicializar> {
  Stream<User?> _sessao = FirebaseAuth.instance.authStateChanges();
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => ThemeController(),
    child: Consumer<ThemeController>(
      builder: (context, tema, child) => StreamBuilder<User?>(
        stream: _sessao,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.hasError) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: tema.temaClaro(),
              darkTheme: tema.temaEscuro(),
              themeMode: tema.temaAtual,
              home: Scaffold(
                body: Center(
                  child: snapshot.hasError
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Não foi possível verificar sua sessão.',
                            ),
                            TextButton(
                              onPressed: () => setState(
                                () => _sessao = FirebaseAuth.instance
                                    .authStateChanges(),
                              ),
                              child: const Text('Tentar novamente'),
                            ),
                          ],
                        )
                      : const CircularProgressIndicator(),
                ),
              ),
            );
          }
          final usuario = snapshot.data;
          // Trocar de conta também recria os controllers e limpa a pilha de navegação.
          return MultiProvider(
            key: ValueKey(usuario?.uid ?? 'visitante'),
            providers: [
              ChangeNotifierProvider(
                create: (_) =>
                    LugaresController(usuarioId: usuario?.uid ?? 'visitante'),
              ),
              ChangeNotifierProvider(create: (_) => GpsController()),
            ],
            child: MaterialApp(
              key: ValueKey(usuario?.uid ?? 'visitante'),
              debugShowCheckedModeBanner: false,
              title: 'Guia Turismo GB',
              initialRoute: 'home',
              theme: tema.temaClaro(),
              darkTheme: tema.temaEscuro(),
              themeMode: tema.temaAtual,
              routes: {
                'home': (_) =>
                    usuario == null ? const LoginScreen() : const HomeScreen(),
                'cadastro_lugar': (_) => usuario == null
                    ? const LoginScreen()
                    : const CadastroLugarScreen(),
                'mapa': (_) =>
                    usuario == null ? const LoginScreen() : const MapaScreen(),
                'lugares': (_) => usuario == null
                    ? const LoginScreen()
                    : const LugaresScreen(),
                'favoritos': (_) => usuario == null
                    ? const LoginScreen()
                    : const LugaresScreen(somenteFavoritos: true),
              },
            ),
          );
        },
      ),
    ),
  );
}
