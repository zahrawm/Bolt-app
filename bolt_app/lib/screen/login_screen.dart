import 'package:bolt_app/provider/auth_provider.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _countryCode = '+233'; // Default to Ghana
  bool _phoneVerified = false;
  bool _isVerifying = false;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePhoneNumber() {
    // Reset verification state when phone number changes
    if (_phoneVerified) {
      setState(() {
        _phoneVerified = false;
        _phoneError = null;
      });
    }

    // Only check if there's enough characters to be a valid number
    if (_phoneController.text.length >= 9) {
      _attemptVerification();
    } else if (_phoneController.text.isNotEmpty) {
      setState(() {
        _phoneError = 'Enter a valid phone number';
      });
    } else {
      setState(() {
        _phoneError = null;
      });
    }
  }

  Future<void> _attemptVerification() async {
    // Don't re-verify if already verifying
    if (_isVerifying) return;

    setState(() {
      _isVerifying = true;
      _phoneError = 'Verifying phone number...';
    });

    // Short delay to simulate verification
    await Future.delayed(const Duration(milliseconds: 800));

    // For demo purposes, always succeed with valid phone number format
    // In a real app, this would make a call to your AuthProvider
    setState(() {
      _phoneVerified = true;
      _phoneError = null;
      _isVerifying = false;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number verified successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacementNamed(context, '/home');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF32D16D),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '17:10',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.signal_cellular_alt, color: Colors.white),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: SizedBox(
                height: 150,
                child: Image.asset('assets/car.png', fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 10),

            const Text(
              'New to Bolt? Enjoy up to 50% off on your first\nride-hailing trips!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your number',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          height: 55,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: CountryCodePicker(
                            onChanged: (CountryCode code) {
                              setState(() {
                                _countryCode = code.dialCode ?? '+233';

                                _phoneVerified = false;
                              });
                            },
                            initialSelection: 'GH',
                            favorite: ['+233', 'GH'],
                            showCountryOnly: false,
                            showOnlyCountryWhenClosed: false,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            onEditingComplete: () {
                              if (_phoneController.text.length >= 9) {
                                _attemptVerification();
                              }
                            },
                            decoration: InputDecoration(
                              hintText: 'Phone number',
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              errorText: _phoneError,
                              errorStyle: TextStyle(
                                color: _isVerifying ? Colors.blue : Colors.red,
                              ),
                              suffixIcon:
                                  _isVerifying
                                      ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: Padding(
                                          padding: EdgeInsets.all(10),
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF32D16D),
                                          ),
                                        ),
                                      )
                                      : _phoneVerified
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Color(0xFF32D16D),
                                      )
                                      : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Center(
                      child: Text('OR', style: TextStyle(color: Colors.grey)),
                    ),
                    const SizedBox(height: 20),

                    authProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildSocialButton(
                          context: context,
                          icon: Icons.g_mobiledata,
                          text: 'Continue with Google',
                          color: Colors.redAccent,
                        ),

                    const SizedBox(height: 50),
                    const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'By signing up, you agree to our '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ', acknowledge our '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(
                            text:
                                ', and confirm that you\'re over 18. We may send promotions...',
                          ),
                        ],
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required BuildContext context,
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: Icon(icon, color: color ?? Colors.black),
        label: Text(text, style: const TextStyle(color: Colors.black)),
        onPressed: () async {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          final success = await authProvider.signInWithGoogle();

          if (success) {
            Navigator.pushReplacementNamed(context, '/home');
          } else {
            final error = authProvider.errorMessage ?? 'Google sign-in failed';
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(error)));
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}
