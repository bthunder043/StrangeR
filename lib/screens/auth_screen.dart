// ignore_for_file: use_build_context_synchronously, avoid_print
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/login_button.dart';
import 'email_auth_screen.dart';
import 'nickname_setup_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff121212),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Spacer(),

              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                  children: [
                    TextSpan(
                      text: "Strange",
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: "R",
                      style: TextStyle(color: Color(0xff6c63ff)),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 10),

              Text(
                "Talk to someone who doesn't know you.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade400,
                  height: 1.4,
                ),
              ),

              SizedBox(height: 40),

              Column(
                children: [
                  LoginButton(
                    icon: Icons.email,
                    text: "Continue with Email",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmailAuthScreen(),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 16),

                  LoginButton(
                    icon: Icons.g_mobiledata,
                    text: "Continue with Google",
                    onTap: () {
                      print("Google login pressed");
                    },
                  ),
                  SizedBox(height: 16),
                  LoginButton(
                    icon: Icons.apple,
                    text: "Continue with Apple",
                    onTap: () {
                      print("Apple login pressed");
                    },
                  ),
                  SizedBox(height: 16),
                  LoginButton(
                    icon: Icons.facebook,
                    text: "Continue with Facebook",
                    onTap: () {
                      print("Facebook login pressed");
                    },
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text("OR", style: TextStyle(color: Colors.grey)),
                      ),
                      Expanded(child: Divider(color: Colors.grey)),
                    ],
                  ),
                  SizedBox(height: 16),
                  LoginButton(
                    icon: Icons.masks,
                    text: "Continue as a Guest",
                    onTap: () async {
                      try {
                        await FirebaseAuth.instance.signInAnonymously();

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NicknameSetup(),
                          ),
                        );
                      } catch (e) {
                        print("Guest login failed: $e");
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
