import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lobby_screen.dart';

class NicknameSetup extends StatefulWidget {
  const NicknameSetup({super.key});

  @override
  State<NicknameSetup> createState() => _NicknameSetupState();
}

class _NicknameSetupState extends State<NicknameSetup> {
  final TextEditingController nicknameController = TextEditingController();

  Future<void> saveUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "nickname": nicknameController.text.trim(),
      "uid": uid,
      "createdAt": FieldValue.serverTimestamp(),
    });
  }

  final List<String> adjectives = [
    "Silent",
    "Hidden",
    "Lost",
    "Lonely",
    "Dark",
    "Wandering",
    "Curious",
    "Mysterious",
    "Midnight",
    "Fading",
  ];

  final List<String> nouns = [
    "Moon",
    "Echo",
    "Nova",
    "Ghost",
    "Shadow",
    "Drifter",
    "Cipher",
    "Star",
    "Comet",
    "Traveler",
  ];

  void generateNickname() {
    final random = Random();

    String adjective = adjectives[random.nextInt(adjectives.length)];
    String noun = nouns[random.nextInt(nouns.length)];

    int tag = random.nextInt(9000) + 1000;

    nicknameController.text = "$adjective$noun$tag";
  }

  @override
  void initState() {
    super.initState();
    generateNickname();
  }

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
              SizedBox(height: 40),
              Text(
                "Choose a nickname",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10),

              Text(
                "This is how other strangers will see you",
                style: TextStyle(color: Colors.grey.shade400),
              ),

              SizedBox(height: 40),

              TextField(
                controller: nicknameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Nickname",
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              SizedBox(height: 20),

              TextButton(
                onPressed: generateNickname,
                child: Text("Suggest another name"),
              ),

              Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (nicknameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Please enter a nickname")),
                      );
                      return;
                    }
                    await saveUserProfile();
                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LobbyScreen()),
                    );
                  },
                  child: Text("Continue"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
