// ignore_for_file: avoid_print

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({super.key, required this.roomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  String? strangerId;
  String strangerNickname = "Stranger";

  StreamSubscription<DocumentSnapshot>? roomSubscription;
  StreamSubscription<DocumentSnapshot>? strangerSubscription;

  bool leavingChat = false;
  bool strangerDisconnected = false;
  bool strangerIsOnline = false;

  @override
  void initState() {
    super.initState();
    listenToRoomStatus();
    loadStrangerNickname();
  }

  Future<void> loadStrangerNickname() async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final roomDoc = await FirebaseFirestore.instance
        .collection("chat_rooms")
        .doc(widget.roomId)
        .get();

    if (!roomDoc.exists) return;

    final roomData = roomDoc.data();
    if (roomData == null) return;

    final users = List<String>.from(roomData["users"] ?? []);

    final foundStrangerId = users.firstWhere(
      (id) => id != currentUid,
      orElse: () => "",
    );

    if (foundStrangerId.isEmpty) return;

    strangerId = foundStrangerId;
    listenToStrangerStatus();

    final strangerDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(strangerId)
        .get();

    if (!strangerDoc.exists) return;

    final strangerData = strangerDoc.data();
    if (strangerData == null) return;

    if (!mounted) return;

    setState(() {
      strangerNickname = strangerData["nickname"] ?? "Stranger";
      strangerIsOnline = strangerData["isOnline"] ?? false;
    });
  }

  Future<void> blockUser() async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    if (strangerId == null || strangerId!.isEmpty) {
      print("block failed: stranger is null or empty");
      return;
    }

    try {
      if (leavingChat) return;
      leavingChat = true;

      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUid)
          .collection("blocked_users")
          .doc(strangerId!)
          .set({
            "uid": strangerId,
            "nickname": strangerNickname,
            "blockedAt": FieldValue.serverTimestamp(),
          });

      await FirebaseFirestore.instance
          .collection("chat_rooms")
          .doc(widget.roomId)
          .update({"isActive": false, "disconnectedBy": currentUid});

      await leavetoLobby(rematch: true);
    } catch (e) {
      leavingChat = false;
      print("Error blocking user: $e");
    }
  }

  void listenToRoomStatus() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    roomSubscription = FirebaseFirestore.instance
        .collection("chat_rooms")
        .doc(widget.roomId)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) {
            if (!leavingChat && mounted) {
              setState(() {
                strangerDisconnected = true;
              });
            }
            return;
          }
          final data = doc.data();
          if (data == null) return;

          final isActive = data["isActive"] ?? true;
          final disconnectedBy = data["disconnectedBy"];

          if (!isActive) {
            if (disconnectedBy == uid) {
              leavetoLobby(rematch: true);
            } else {
              if (mounted) {
                setState(() {
                  strangerDisconnected = true;
                });
              }
            }
          }
        });
  }

  void listenToStrangerStatus() {
    if (strangerId == null || strangerId!.isEmpty) return;
    strangerSubscription?.cancel();

    strangerSubscription = FirebaseFirestore.instance
        .collection("users")
        .doc(strangerId!)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;

          final data = doc.data();
          if (data == null) return;

          if (!mounted) return;

          setState(() {
            strangerNickname = data["nickname"] ?? "Stranger";
            strangerIsOnline = data["isOnline"] ?? false;
          });
        });
  }

  Future<void> leavetoLobby({bool rematch = false}) async {
    if (!mounted) return;

    Navigator.pop(context, rematch ? "rematch" : null);
  }

  Future<void> sendMessage() async {
    if (leavingChat || strangerDisconnected) return;
    if (strangerDisconnected) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection("chat_rooms")
        .doc(widget.roomId)
        .collection("messages")
        .add({
          "text": text,
          "sender": user.uid,
          "createdAt": FieldValue.serverTimestamp(),
        });

    messageController.clear();
  }

  Future<void> skipStranger() async {
    if (leavingChat) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    leavingChat = true;

    await FirebaseFirestore.instance
        .collection("chat_rooms")
        .doc(widget.roomId)
        .update({"isActive": false, "disconnectedBy": uid});
    await leavetoLobby(rematch: true);
  }

  @override
  void dispose() {
    roomSubscription?.cancel();
    strangerSubscription?.cancel();
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Color(0xff121212),
      appBar: AppBar(
        backgroundColor: Color(0xff121212),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strangerNickname, style: TextStyle(color: Colors.white)),
            Text(
              strangerIsOnline ? "Online" : "Offline",
              style: TextStyle(
                color: strangerIsOnline ? Colors.green : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: skipStranger, icon: Icon(Icons.skip_next)),
          IconButton(
            onPressed: () {
              blockUser();
            },
            icon: const Icon(Icons.block, color: Colors.red),
          ),
        ],
      ),
      body: Column(
        children: [
          if (strangerDisconnected)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.fromLTRB(12, 12, 12, 0),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "Stranger disconnected!",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () => leavetoLobby(rematch: true),
                    child: Text(
                      "Find another",
                      style: TextStyle(color: Color(0xff6c63ff)),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chat_rooms")
                  .doc(widget.roomId)
                  .collection("messages")
                  .orderBy("createdAt", descending: false)
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error: ${snapshot.error}",
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: Color(0xff6c63ff)),
                  );
                }

                final messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (scrollController.hasClients) {
                    scrollController.animateTo(
                      scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg["sender"] == uid;

                    return Container(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.7,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isMe ? Color(0xff636cff) : Color(0xff2a2a40),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(isMe ? 16 : 4),
                              bottomRight: Radius.circular(isMe ? 4 : 16),
                            ),
                          ),
                          child: Text(
                            msg["text"],
                            style: TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          //message input
          Container(
            padding: EdgeInsets.fromLTRB(10, 8, 10, 12),
            color: Color(0xff121212),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Color(0xff1e1e1e),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Color(0xff2a2a40)),
                    ),
                    child: TextField(
                      style: TextStyle(color: Colors.white),
                      controller: messageController,
                      enabled: !strangerDisconnected && !leavingChat,
                      decoration: InputDecoration(
                        hintText: strangerDisconnected
                            ? "Chat ended"
                            : "Type a message...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Color(0xff6c63ff),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: strangerDisconnected || leavingChat ? null : sendMessage,
                    icon: Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
