import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _usersCollection = 'users';

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;
  bool _phoneNumberVerified = false;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      _updateUserData(user);
      notifyListeners();
    });
    _user = _auth.currentUser;
    _updateUserData(_user);
  }

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;
  bool get phoneNumberVerified => _phoneNumberVerified;

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    debugPrint('Auth Error: $error');
    notifyListeners();
  }

  Future<void> _updateUserData(User? user) async {
    if (user != null) {
      try {
        await _firestore.collection(_usersCollection).doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'phoneNumberVerified': _phoneNumberVerified,
          'lastSignIn': DateTime.now(),
        }, SetOptions(merge: true));
        debugPrint('User data updated in Firestore for UID: ${user.uid}');
      } catch (e) {
        debugPrint("Error updating user data in Firestore: $e");
      }
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        _setError("Google sign-in was cancelled.");
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      _user = userCredential.user;

      if (_user == null) {
        _setLoading(false);
        _setError("User ID cannot be found after Google Sign-In.");
        return false;
      }

      debugPrint("Signed in with Google: UID = ${_user!.uid}");

      await _updateUserData(_user);
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError("Google Sign-In failed: $e");
      return false;
    }
  }

  Future<bool> verifyPhoneNumber(String phoneNumber) async {
    try {
      _setLoading(true);
      _setError(null);

      UserCredential userCredential = await _auth.signInAnonymously();
      _user = userCredential.user;

      await userCredential.user?.updatePhoneNumber(
        PhoneAuthProvider.credential(
          verificationId: 'development-verification-id',
          smsCode: '123456',
        ),
      );

      _phoneNumberVerified = true;
      await _updateUserData(_user);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError("Phone verification failed: $e");
      return false;
    }
  }

  Future<bool> linkPhoneNumber(String phoneNumber) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_user == null) {
        final userCredential = await _auth.signInAnonymously();
        _user = userCredential.user;
      }

      await _auth.currentUser?.updateDisplayName(phoneNumber);
      _phoneNumberVerified = true;
      await _updateUserData(_user);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError("Phone linking failed: $e");
      return false;
    }
  }

  Future<bool> signInWithPhoneNumberCustomFlow(String phoneNumber) async {
    try {
      _setLoading(true);
      _setError(null);

      await Future.delayed(const Duration(seconds: 2));

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: 'simulated-verification',
        smsCode: '000000',
      );

      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      _user = userCredential.user;

      if (_user == null) {
        _setLoading(false);
        _setError("User ID cannot be found after phone sign-in.");
        return false;
      }

      _phoneNumberVerified = true;
      await _updateUserData(_user);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError("Phone Sign-In failed: $e");
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
      _phoneNumberVerified = false;
      notifyListeners();
    } catch (e) {
      _setError("Sign out failed: $e");
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
