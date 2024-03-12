import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:poke/design_system/poke_app_bar.dart';
import 'package:poke/design_system/poke_async_button.dart';
import 'package:poke/design_system/poke_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isAnonymous =
        FirebaseAuth.instance.currentUser?.isAnonymous ?? false;

    return Scaffold(
        appBar: PokeAppBar(context),
        body: Center(
          child: Column(
            children: [
              if (isAnonymous)
                PokeText('Hello anonymous')
              else
                PokeText(
                    'Hello ${FirebaseAuth.instance.currentUser?.displayName ?? 'unknown'}'),
              if (isAnonymous)
                PokeAsyncButton.once(
                  text: 'Make permanent',
                  onPressed: linkWithGoogle,
                ),
              PokeAsyncButton.rerunnable(
                text: 'Log out',
                onPressed: FirebaseAuth.instance.signOut,
              )
            ],
          ),
        ));
  }

  Future<UserCredential> linkWithGoogle() async {
    final googleSignIn = GoogleSignIn();
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      return await FirebaseAuth.instance.currentUser!
          .linkWithCredential(credential);
    } finally {
      // The account selected from the popup this function triggers is cached
      // indefinitely unless we call `GoogleSignIn.disconnect`. If anything goes
      // wrong we better disconnect and allow the user to try with another google
      // account
      googleSignIn.disconnect();
    }

    // TODO: handle errors!
    //   account already associated with another account
    //      create acc with email
    //      log in anonymously and try to link; will fail because email already in use
    /*try {} on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "provider-already-linked":
          print("The provider has already been linked to the user.");
          break;
        case "invalid-credential":
          print("The provider's credential is not valid.");
          break;
        case "credential-already-in-use":
          print("The account corresponding to the credential already exists, "
              "or is already linked to a Firebase User.");
          break;
        // See the API reference for the full list of error codes.
        default:
          print("Unknown error.");
      }
    }*/
  }
}
