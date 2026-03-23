// ignore_for_file: avoid_print

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stranger/screens/lobby_screen.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({super.key, required this.roomId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  StreamSubscription<DocumentSnapshot>? roomSubscription;
  bool leavingChat = false;

  @override
  void initState() {
    super.initState();
    listentoRoomStatus();
  }

  void listentoRoomStatus() {
    roomSubscription = FirebaseFirestore.instance
        .collection("chat_rooms")
        .doc(widget.roomId)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) {
            leavetoLobby();
            return;
          }
          final data = doc.data();
          if (data == null) return;

          if (data["isActive"] == false) {
            leavetoLobby();
          }
        });
  }

  Future<void> leavetoLobby() async {
    if (leavingChat) return;
    leavingChat = true;

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LobbyScreen()),
      (route) => false,
    );
  }

  Future<void> sendMessage() async {
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

    await FirebaseFirestore.instance
        .collection("chat_rooms")
        .doc(widget.roomId)
        .update({"isActive": false});
    await leavetoLobby();
  }

  @override
  void dispose() {
    roomSubscription?.cancel();
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
        title: const Text("StrangeR"),
        actions: [
          IconButton(onPressed: skipStranger, icon: Icon(Icons.skip_next)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("chat_rooms")
                  .doc(widget.roomId)
                  .collection("messages")
                  .orderBy("createdAt", descending: false)
                  .snapshots(),

              builder: (context, snapshot) {
                print("snapshot error: ${snapshot.error}");
                print("docs length: ${snapshot.data?.docs.length}");
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
                      decoration: InputDecoration(
                        hintText: "Type a message...",
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
                    onPressed: sendMessage,
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
