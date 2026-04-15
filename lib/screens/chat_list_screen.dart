// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  String formatTime(Timestamp? timestamp) {
    if (timestamp == null) return "";

    final date = timestamp.toDate();
    final now = DateTime.now();

    final isToday =
        date.day == now.day && date.month == now.month && date.year == now.year;

    if (isToday) {
      return "${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}";
    } else {
      return "${date.day}/${date.month}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: const Color(0xff121212),
      appBar: AppBar(
        backgroundColor: const Color(0xff121212),
        title: const Text("Chats", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chat_rooms")
            .where("users", arrayContains: uid)
            .orderBy("lastMessageTime", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          print("chat list state: ${snapshot.connectionState}");
          print("chat list hasData: ${snapshot.hasData}");
          print("chat list error: ${snapshot.error}");

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xff6c63ff)),
            );
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                "No chats yet",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final Map<String, QueryDocumentSnapshot> uniqueChats = {};

          for (final chat in chats) {
            final users = List<String>.from(chat["users"] ?? []);
            final strangerId = users.firstWhere(
              (id) => id != uid,
              orElse: () => "",
            );
            if (strangerId.isEmpty) continue;

            uniqueChats.putIfAbsent(strangerId, () => chat);
          }

          final uniqueChatList = uniqueChats.values.toList();

          return ListView.builder(
            itemCount: uniqueChatList.length,
            itemBuilder: (context, index) {
              final chat = uniqueChatList[index];
              final users = List<String>.from(chat["users"] ?? []);

              final strangerId = users.firstWhere(
                (id) => id != uid,
                orElse: () => "",
              );

              if (strangerId.isEmpty) {
                return const SizedBox.shrink();
              }

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(strangerId)
                    .get(),
                builder: (context, userSnapshot) {
                  String nickname = "Stranger";

                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    // 👇 STILL RETURN A CLICKABLE TILE
                    return ListTile(
                      title: const Text(
                        "Loading...",
                        style: TextStyle(color: Colors.white),
                      ),
                      onTap: () {
                        print("Tapped chat: ${chat.id}");

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(roomId: chat.id),
                          ),
                        );
                      },
                    );
                  }

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final data =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    nickname = data?["nickname"] ?? "Stranger";
                  }

                  return ListTile(
                    title: Text(
                      nickname,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      chat["lastMessage"] ?? "",
                      style: const TextStyle(color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      formatTime(chat["lastMessageTime"]),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    onTap: () {
                      print("Tapped chat: ${chat.id}");

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(roomId: chat.id),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
