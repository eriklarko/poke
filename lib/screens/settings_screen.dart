import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:poke/design_system/poke_async_button.dart';
import 'package:poke/design_system/poke_button.dart';
import 'package:poke/design_system/poke_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isAnonymous =
        FirebaseAuth.instance.currentUser?.isAnonymous ?? false;

    return Scaffold(
        body: Center(
      child: Column(
        children: [
          if (isAnonymous)
            PokeText('Hello anonymous')
          else
            PokeText(
                'Hello ${FirebaseAuth.instance.currentUser?.displayName ?? 'unknown'}'),
          if (isAnonymous)
            PokeAsyncButton(
              text: 'Make permanent',
              onPressed: linkWithGoogle,
            ),
          PokeAsyncButton(
            text: 'Log out',
            onPressed: FirebaseAuth.instance.signOut,
          )
        ],
      ),
    ));
  }

  Future<UserCredential> linkWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

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

    // TODO: handle errors!
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
