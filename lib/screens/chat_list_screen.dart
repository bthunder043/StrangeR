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
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return "$hour:$minute $period";
    } else {
      return "${date.day}/${date.month}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor:  Color(0xff121212),
      appBar: AppBar(
        backgroundColor:  Color(0xff121212),
        elevation: 0,
        title: Text(
          "Chats",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("chat_rooms")
            .where("users", arrayContains: uid)
            .orderBy("lastMessageTime", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style:  TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData) {
            return  Center(
              child: CircularProgressIndicator(
                color: Color(0xff6c63ff),
              ),
            );
          }

          final chats = snapshot.data!.docs;

          if (chats.isEmpty) {
            return Center(
              child: Padding(
                padding:  EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.04),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                      child:  Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                     SizedBox(height: 20),
                     Text(
                      "No chats yet",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                     SizedBox(height: 8),
                    Text(
                      "Your recent conversations will appear here.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
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

          return ListView.separated(
            padding:  EdgeInsets.fromLTRB(16, 14, 16, 120),
            itemCount: uniqueChatList.length,
            separatorBuilder: (_, _) =>  SizedBox(height: 12),
            itemBuilder: (context, index) {
              final chat = uniqueChatList[index];
              final users = List<String>.from(chat["users"] ?? []);

              final strangerId = users.firstWhere(
                (id) => id != uid,
                orElse: () => "",
              );

              if (strangerId.isEmpty) {
                return  SizedBox.shrink();
              }

              final unreadCounts =
                  (chat["unreadCounts"] as Map<String, dynamic>?) ?? {};
              final unread = unreadCounts[uid] ?? 0;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("users")
                    .doc(strangerId)
                    .get(),
                builder: (context, userSnapshot) {
                  String nickname = "Stranger";
                  bool isOnline = false;

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final data =
                        userSnapshot.data!.data() as Map<String, dynamic>?;
                    nickname = data?["nickname"] ?? "Stranger";
                    isOnline = data?["isOnline"] ?? false;
                  }

                  return InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(roomId: chat.id),
                        ),
                      );
                    },
                    child: Container(
                      padding:  EdgeInsets.all(14),
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
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor:  Color(0xff2a2a40),
                                child: Text(
                                  nickname.isNotEmpty
                                      ? nickname[0].toUpperCase()
                                      : "?",
                                  style:  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: isOnline
                                        ? Colors.green
                                        : Colors.grey.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color:  Color(0xff1b1b1b),
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                           SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nickname,
                                  style:  TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                 SizedBox(height: 4),
                                Text(
                                  chat["lastMessage"] ?? "",
                                  style:  TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                           SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatTime(chat["lastMessageTime"]),
                                style:  TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                               SizedBox(height: 8),
                              unread > 0
                                  ? Container(
                                      padding:  EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color:  Color(0xff6c63ff),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        unread.toString(),
                                        style:  TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    )
                                  :  SizedBox(height: 22),
                            ],
                          ),
                        ],
                      ),
                    ),
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