import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:guia_turismo/themes/inicializar.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const Inicializar());
}