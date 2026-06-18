import 'package:firebase_auth/firebase_auth.dart';

class FirebaseFunction {
  static Future<UserCredential?> createAccount(String email, String password) async {
    try {
      UserCredential credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        print('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        print('The account already exists for that email.');
      } else {
        print('Error: ${e.message}');
      }
      return null;
    } catch (e) {
      print('Unknown error: $e');
      return null;
    }
  }
}
