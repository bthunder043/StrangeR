import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stranger/screens/nickname_setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => NicknameSetup()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff121212),
      appBar: AppBar(
        backgroundColor: Color(0xff121212),
        title: Text("Settings", style: TextStyle(color: Colors.white)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xff1b1b1b),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Account",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "More options will be added later.",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Color(0xff1b1b1b),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: Colors.white),
                  title: Text(
                    "Change nickname",
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey),
                ),
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
                ListTile(
                  leading: Icon(Icons.logout_rounded, color: Colors.red),
                  title: Text("Logout", style: TextStyle(color: Colors.red)),
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
