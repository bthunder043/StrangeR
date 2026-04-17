import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'edit_nickname_screen.dart';
import 'nickname_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
   const SettingsScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) =>  NicknameSetup()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:  Color(0xff121212),
      appBar: AppBar(
        backgroundColor:  Color(0xff121212),
        elevation: 0,
        title:  Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding:  EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Container(
            padding:  EdgeInsets.all(18),
            decoration: BoxDecoration(
              color:  Color(0xff1b1b1b),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset:  Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text(
                  "Account",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                 SizedBox(height: 8),
                Text(
                  "Manage your profile and app preferences.",
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
           SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color:  Color(0xff1b1b1b),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset:  Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding:  EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading:  Icon(Icons.edit_rounded, color: Colors.white),
                  title:  Text(
                    "Change nickname",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing:  Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>  EditNicknameScreen(),
                      ),
                    );
                  },
                ),
                Divider(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                ListTile(
                  contentPadding:  EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading:  Icon(Icons.logout_rounded, color: Colors.red),
                  title:  Text(
                    "Logout",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: () => logout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}