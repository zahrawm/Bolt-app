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

  Future<void> verifyPhoneNumber(String phoneNumber) async {
    _setLoading(true);
    _setError(null);

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
        _setLoading(false);
      },
      verificationFailed: (FirebaseAuthException e) {
        _setLoading(false);
        _setError(e.message);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _setLoading(false);
        notifyListeners();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<bool> verifyOTP(String otpCode) async {
    try {
      _setLoading(true);
      _setError(null);

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otpCode,
      );

      await _auth.signInWithCredential(credential);

      _setLoading(false);
      return true;
    } catch (e) {
      _setLoading(false);
      _setError("Invalid OTP or verification failed");
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _auth.signOut();
      await _googleSignIn.signOut();
      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }
}
