import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth=FirebaseAuth.instance;

  Future<User?> signInAnonymously() async
  {
    try{
      UserCredential result=await _auth.signInAnonymously();
      return result.user;
    }catch(e)
    {
      print("Anonymous Sign In Error:$e");
      return null;
    }
  }
  Future<void> signOut() async{
    await _auth.signOut();
  }

  Stream<User?> get userChanges=> _auth.authStateChanges();
}