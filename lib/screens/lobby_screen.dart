// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
            if (!mounted) return;

            if (snapshot.docs.isNotEmpty && !hasNavigated && searching) {
              hasNavigated = true;
              retryTimer?.cancel();

              setState(() {
                searching = false;
              });

              final roomId = snapshot.docs.first.id;
              print("navigating to chat room: $roomId");

              await Future.delayed( Duration(milliseconds: 300));

              if (!mounted) return;

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(roomId: roomId),
                ),
              );

              if (!mounted) return;

              hasNavigated = false;

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
    retryTimer = Timer.periodic( Duration(milliseconds: 700), (_) async {
      if (!mounted || !searching || hasNavigated) {
        retryTimer?.cancel();
        return;
      }

      await startMatching();
    });
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
      backgroundColor:  Color(0xff121212),
      appBar: AppBar(
        backgroundColor:  Color(0xff121212),
        elevation: 0,
        centerTitle: false,
        title: RichText(
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Center(
              child: searching
                  ? Padding(
                      padding:  EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           SizedBox(height: 8),
                          Container(
                            padding:  EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:  Color(
                                0xff6c63ff,
                              ).withValues(alpha: 0.10),
                              border: Border.all(
                                color:  Color(
                                  0xff6c63ff,
                                ).withValues(alpha: 0.18),
                              ),
                            ),
                            child:  SizedBox(
                              width: 34,
                              height: 34,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Color(0xff6c63ff),
                              ),
                            ),
                          ),
                           SizedBox(height: 24),
                           Text(
                            "Searching for a stranger...",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                           SizedBox(height: 8),
                          Text(
                            "Please wait while we find someone for you.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                           SizedBox(height: 24),
                          TextButton(
                            onPressed: cancelSearch,
                            child:  Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Color(0xff6c63ff),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding:  EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.04),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            child:  Icon(
                              Icons.chat_bubble_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                           SizedBox(height: 28),
                           Text(
                            "Start talking to a stranger",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                           SizedBox(height: 10),
                          Text(
                            "Connect instantly and chat anonymously in real time.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                           SizedBox(height: 30),
                          SizedBox(
                            width: 220,
                            child: ElevatedButton(
                              onPressed: startChat,
                              child:  Text("Start chat"),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}