// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> startMatching(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;

  print("MY UID: $uid");

  //deactivating old rooms
  final oldRooms = await FirebaseFirestore.instance
      .collection("chat_rooms")
      .where("users", arrayContains: uid)
      .where("isActive", isEqualTo: true)
      .get();

  for (final room in oldRooms.docs) {
    await room.reference.update({"isActive": false});
  }

  final waitingSnapshot = await FirebaseFirestore.instance
      .collection("waiting_users")
      .get();

  final availableUsers = waitingSnapshot.docs
      .where((doc) => doc.id != uid)
      .toList();

  if (availableUsers.isNotEmpty) {
    final strangerId = availableUsers.first.id;

    print("Match found with: $strangerId");

    final room = await FirebaseFirestore.instance.collection("chat_rooms").add({
      "users": [uid, strangerId],
      "createdAt": FieldValue.serverTimestamp(),
      "isActive": true,
    });
    print("Created room with ID: ${room.id}");

    await FirebaseFirestore.instance
        .collection("waiting_users")
        .doc(strangerId)
        .delete();

    await FirebaseFirestore.instance
        .collection("waiting_users")
        .doc(uid)
        .delete();
  } else {
    print("No match, adding user to waiting list");

    await FirebaseFirestore.instance.collection("waiting_users").doc(uid).set({
      "joinedAt": FieldValue.serverTimestamp(),
    });
  }
}
