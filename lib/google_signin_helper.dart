import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInProvider extends ChangeNotifier {
  final googleSignIn = GoogleSignIn();

  GoogleSignInAccount? _googleUser;

  GoogleSignInAccount? get user => _googleUser;

  Future googleLogin() async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;
    _googleUser = googleUser;
    final googleAuth = await googleUser.authentication;
    final creds = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    print('google id token is ');
    print(creds.idToken);

    // print(creds.accessToken);
    final check = await FirebaseAuth.instance.signInWithCredential(creds);
    print(check);
    print(check.additionalUserInfo);
    final user = FirebaseAuth.instance.currentUser;
    final token = await user!.getIdToken(true);
    print('firebase id token :');
    print(token.length);
    print(token.substring(0, 500));
    print(token.substring(500, token.length));
    print('Length of id token is : ');

    print('truncated id token is:');
    print(token);
    notifyListeners();
  }

  Future logout() async {
    await googleSignIn.disconnect();
    FirebaseAuth.instance.signOut();
    notifyListeners();
  }
}
