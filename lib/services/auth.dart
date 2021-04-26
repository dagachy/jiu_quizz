import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User get getUser => _auth.currentUser;

  Stream<User> get user => _auth.authStateChanges();

  Future<UserCredential> googleSignIn() async {
    try {
      GoogleSignInAccount googleSignInAccount = await _googleSignIn.signIn();
      GoogleSignInAuthentication googleAuth =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);

      UserCredential uc = await _auth.signInWithCredential(credential);
      return uc;
    } catch (error) {
      print(error);
      return null;
    }
  }

  Future<UserCredential> anonLogin() async {
    UserCredential uc = await _auth.signInAnonymously();
    updateUserData(uc);
    return uc;
  }

  Future<void> updateUserData(UserCredential uc) {
    DocumentReference reportRef = _db.collection('reports').doc(uc.user.uid);

    return reportRef.set({'uid': uc.user.uid, 'lastActivity': DateTime.now()},
        SetOptions(merge: true));
  }

  Future<void> signOut() {
    return _auth.signOut();
  }
}
