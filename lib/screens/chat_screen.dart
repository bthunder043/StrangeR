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
          "timestamp": FieldValue.serverTimestamp(),
        });

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Color(0xff121212),
      appBar: AppBar(
        backgroundColor: Color(0xff121212),
        title: const Text("Stranger"),
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
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  padding: EdgeInsets.all(10),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg["sender"] == uid;

                    return Container(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      padding: EdgeInsets.all(10),
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? Color(0xff377771) : Color(0xffaf6565),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          msg["text"],
                          style: TextStyle(color: Colors.white),
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
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(hintText: "Type a message..."),
                  ),
                ),

                IconButton(onPressed: sendMessage, icon: Icon(Icons.send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
