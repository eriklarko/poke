import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/design_system/poke_async_button.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PokeAppBar(context),
      body: Center(
        child: Column(
          children: [
            PokeAsyncButton(
              text: 'Log in anonymously',
              onPressed: _logInAnonymously,
            ),
            PokeAsyncButton(
              text: 'Log in with Google',
              onPressed: _logInWithGoogle,
            ),
          ],
        ),
      ),
    );
  }

  // TODO: Need some way to graduate these accounts. See
  // https://firebase.google.com/docs/auth/flutter/anonymous-auth#convert_an_anonymous_account_to_a_permanent_account
  //
  // I'm thinking maybe a button in some settings screen somewhere.
  Future<UserCredential> _logInAnonymously() async {
    return await FirebaseAuth.instance.signInAnonymously();
  }

  Future<UserCredential> _logInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
