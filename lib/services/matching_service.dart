import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';


Future<void> startMatching(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;

  final waitingSnapshot = await FirebaseFirestore.instance
      .collection("waiting_users")
      .limit(1)
      .get();

  if (waitingSnapshot.docs.isNotEmpty && waitingSnapshot.docs.first.id != uid) {
    final strangerId = waitingSnapshot.docs.first.id;

    // final room = await FirebaseFirestore.instance.collection("chat_rooms").add({
    //   "users": [uid, strangerId],
    //   "createdAt": FieldValue.serverTimestamp(),
    // });

    await FirebaseFirestore.instance
        .collection("waiting_users")
        .doc(strangerId)
        .delete();

  } else {
    await FirebaseFirestore.instance.collection("waiting_users").doc(uid).set({
      "joinedAt": FieldValue.serverTimestamp(),
    });
  }
}
