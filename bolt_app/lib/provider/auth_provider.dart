import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  String? _verificationId;
  bool _phoneNumberVerified = false;

  AuthProvider() {
    _user = _auth.currentUser;
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
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
    notifyListeners();
  }

  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(false);
        return false;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> verifyPhoneNumber(String phoneNumber) async {
    try {
      _setLoading(true);
      _setError(null);

      UserCredential userCredential = await _auth.signInAnonymously();

      await userCredential.user?.updatePhoneNumber(
        PhoneAuthProvider.credential(
          verificationId: 'development-verification-id',
          smsCode: '123456',
        ),
      );

      _phoneNumberVerified = true;

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  Future<bool> linkPhoneNumber(String phoneNumber) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_user == null) {
        await _auth.signInAnonymously();
      }

      await _auth.currentUser?.updateDisplayName(phoneNumber);

      _phoneNumberVerified = true;

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
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

      await _auth.signInWithCredential(credential);

      _phoneNumberVerified = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _phoneNumberVerified = false;
    } catch (e) {
      _setError(e.toString());
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
