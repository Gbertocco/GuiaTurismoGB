import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static final _google = GoogleSignIn.instance;
  static Future<void>? _inicializacao;

  static Future<UserCredential> entrar() async {
    await (_inicializacao ??= _google.initialize());

    final conta = await _google.authenticate();

    final credencial = GoogleAuthProvider.credential(
      idToken: conta.authentication.idToken,
    );

    return FirebaseAuth.instance.signInWithCredential(credencial);
  }

  static Future<void> sair() async {
    await FirebaseAuth.instance.signOut();
    await (_inicializacao ??= _google.initialize());
    await _google.signOut();
  }
}