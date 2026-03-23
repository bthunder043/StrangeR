// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services//matching_service.dart';
import 'chat_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  bool searching = false;
  bool hasNavigated = false;
  StreamSubscription<QuerySnapshot>? matchSubscription;

  void listenForMatch() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    print("Listening for match for UID: $uid");

    matchSubscription?.cancel();

    matchSubscription = FirebaseFirestore.instance
        .collection("chat_rooms")
        .where("isActive", isEqualTo: true)
        .where("users", arrayContains: uid)
        .orderBy("createdAt", descending: true)
        .snapshots()
        .listen(
          (snapshot) async {
            print("Chat room snapshot received: ${snapshot.docs.length}");

            if (snapshot.docs.isNotEmpty && !hasNavigated) {
              hasNavigated = true;
              final roomId = snapshot.docs.first.id;

              print("navigating to chat room: $roomId");

              await Future.delayed(const Duration(milliseconds: 500));

              if (!mounted) return;

              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatScreen(roomId: roomId)),
              ).then((_) {
                hasNavigated = false;
                if (mounted) {
                  setState(() {
                    searching = false;
                  });
                }
              });
            }
          },
          onError: (error) {
            print("listenForMatch error: $error");
          },
        );
  }

  void startChat() async {
    setState(() {
      searching = true;
      hasNavigated = false;
    });

    listenForMatch();
    await startMatching(context);
  }

  @override
  void dispose() {
    super.dispose();
    matchSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff121212),
      appBar: AppBar(
        backgroundColor: Color(0xff121212),
        elevation: 0,
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
            children: [
              TextSpan(
                text: "Strange",
                style: TextStyle(color: Colors.grey),
              ),
              TextSpan(
                text: "R",
                style: TextStyle(color: Color(0xff6c63ff)),
              ),
            ],
          ),
        ),
      ),

      body: Center(
        child: searching
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xff6c63ff)),
                  SizedBox(height: 20),

                  Text(
                    "Searching for a stranger...",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(Icons.chat, size: 80, color: Colors.white),

                  SizedBox(height: 20),

                  Text(
                    "Start talking to a stranger",
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),

                  SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: startChat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff6c63ff),
                      padding: EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                    ),
                    child: Text(
                      "Start chat",
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
