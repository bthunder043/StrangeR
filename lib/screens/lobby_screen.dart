// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stranger/screens/chat_list_screen.dart';
import 'package:stranger/services/presence_service.dart';
import '../services/matching_service.dart';
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
  Timer? retryTimer;

  void listenForMatch() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

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

            if (!mounted) return;

            if (snapshot.docs.isNotEmpty && !hasNavigated && searching) {
              hasNavigated = true;
              retryTimer?.cancel();

              setState(() {
                searching = false;
              });

              final roomId = snapshot.docs.first.id;

              print("navigating to chat room: $roomId");

              await Future.delayed(const Duration(milliseconds: 500));

              if (!mounted) return;

              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatScreen(roomId: roomId)),
              );

              hasNavigated = false;

              if (!mounted) return;

              if (result == "rematch") {
                startChat();
              }
            }
          },
          onError: (error) {
            print("listenForMatch error: $error");
          },
        );
  }

  Future<void> startChat() async {
    if (searching) return;

    setState(() {
      searching = true;
      hasNavigated = false;
    });

    await deactivateMyActiveRooms();

    listenForMatch();
    await startMatching();

    retryTimer?.cancel();
    retryTimer = Timer.periodic(Duration(milliseconds: 700), (_) async {
      if (!mounted || !searching || hasNavigated) {
        retryTimer?.cancel();
        return;
      }
    });

    await startMatching();
  }

  Future<void> cancelSearch() async {
    retryTimer?.cancel();
    await cancelWaiting();
    await matchSubscription?.cancel();

    if (!mounted) return;

    setState(() {
      searching = false;
      hasNavigated = false;
    });
  }

  @override
  void initState() {
    super.initState();
    PresenceService.setUserOnline();
  }

  @override
  void dispose() {
    retryTimer?.cancel();
    matchSubscription?.cancel();
    PresenceService.setUserOffline();
    super.dispose();
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
        actions: [
          IconButton(
            tooltip: "Chats",
            icon: Icon(Icons.history, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ChatListScreen()),
              );
            },
          ),
        ],
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
