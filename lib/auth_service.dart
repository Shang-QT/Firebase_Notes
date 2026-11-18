import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn? _googleSignin = kIsWeb ? null : GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    if (kIsWeb) {

      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      UserCredential userCredential = await _auth.signInWithPopup(googleProvider);
      return userCredential.user;
    }
    else {
      final googleUser = await _googleSignin!.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return (await _auth.signInWithCredential(credential)).user;
    }
  }

  Future <User?> registerWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch(e) {
      print("Error: $e:");
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch(e) {
      print("Error: $e:");
      return null;
    }
  }

  Future <void> signOut() async {
    if (!kIsWeb) {
      await _googleSignin?.signOut();
    }
    await _auth.signOut();
  }

  Stream<User?> get userStream => _auth.authStateChanges();
}