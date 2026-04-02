// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> startMatching() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;

  print("MY UID: $uid");

  final waitingSnapshot = await FirebaseFirestore.instance
      .collection("waiting_users")
      .orderBy("joinedAt")
      .get();

  final blockedSnapshot = await FirebaseFirestore.instance
      .collection("users")
      .doc(uid)
      .collection("blocked_users")
      .get();

  final blockedUserIds = blockedSnapshot.docs.map((doc) => doc.id).toSet();

  final availableUsers = <QueryDocumentSnapshot>[];

  for (final doc in waitingSnapshot.docs) {
    final strangerUid = doc.id;
    if (strangerUid == uid) continue;
    if (blockedUserIds.contains(strangerUid)) continue;

    final blockedMeDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(strangerUid)
        .collection("blocked_users")
        .doc(uid)
        .get();

    if (blockedMeDoc.exists) continue;

    availableUsers.add(doc);
  }

  if (availableUsers.isNotEmpty) {
    final strangerId = availableUsers.first.id;

    print("Match found with: $strangerId");

    final room = await FirebaseFirestore.instance.collection("chat_rooms").add({
      "users": [uid, strangerId],
      "createdAt": Timestamp.now(),
      "isActive": true,
      "disconnectedBy": null,
    });
    print("Created room with ID: ${room.id}");

    await FirebaseFirestore.instance
        .collection("waiting_users")
        .doc(strangerId)
        .delete()
        .catchError((_) {});

    await FirebaseFirestore.instance
        .collection("waiting_users")
        .doc(uid)
        .delete()
        .catchError((_) {});
  } else {
    print("No match, adding user to waiting list");

    await FirebaseFirestore.instance.collection("waiting_users").doc(uid).set({
      "joinedAt": FieldValue.serverTimestamp(),
    });
  }
}

Future<void> leaveRoom(String roomId) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await FirebaseFirestore.instance.collection("chat_rooms").doc(roomId).update({
    "isActive": false,
    "disconnectedBy": user.uid,
  });
}

Future<void> cancelWaiting() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await FirebaseFirestore.instance
      .collection("waiting_users")
      .doc(user.uid)
      .delete()
      .catchError((_) {});
}
