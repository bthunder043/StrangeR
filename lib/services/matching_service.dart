// ignore_for_file: avoid_print

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> deactivateMyActiveRooms() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;

  final oldRooms = await FirebaseFirestore.instance
      .collection("chat_rooms")
      .where("users", arrayContains: uid)
      .where("isActive", isEqualTo: true)
      .get();

  for (final room in oldRooms.docs) {
    await room.reference.update({"isActive": false, "disconnectedBy": uid});
  }
}

Future<void> startMatching() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final uid = user.uid;
  print("MY UID: $uid");

  final existingRoom = await FirebaseFirestore.instance
      .collection("chat_rooms")
      .where("users", arrayContains: uid)
      .where("isActive", isEqualTo: true)
      .limit(1)
      .get();

  if (existingRoom.docs.isNotEmpty) {
    print("User already has an active room, skipping matching");
    return;
  }

  final db = FirebaseFirestore.instance;
  final waitingRef = db.collection("waiting_users");

  // get blocked users
  final blockedSnapshot = await db
      .collection("users")
      .doc(uid)
      .collection("blocked_users")
      .get();

  final blockedUserIds = blockedSnapshot.docs.map((doc) => doc.id).toSet();

  final waitingSnapshot = await waitingRef
      .where("matched", isEqualTo: false)
      .orderBy("joinedAt")
      .get();

  for (final doc in waitingSnapshot.docs) {
    final strangerId = doc.id;

    if (strangerId == uid) continue;
    if (blockedUserIds.contains(strangerId)) continue;

    final blockedMeDoc = await db
        .collection("users")
        .doc(strangerId)
        .collection("blocked_users")
        .doc(uid)
        .get();

    if (blockedMeDoc.exists) continue;

    try {
      await db.runTransaction((transaction) async {
        final strangerRef = waitingRef.doc(strangerId);
        final myRef = waitingRef.doc(uid);

        final strangerSnap = await transaction.get(strangerRef);

        if (!strangerSnap.exists) {
          throw Exception("Stranger disappeared");
        }

        final data = strangerSnap.data();
        if (data == null) throw Exception("No data");

        if (data["matched"] == true) {
          throw Exception("Already matched");
        }

        // claim stranger
        transaction.update(strangerRef, {"matched": true});

        // create room
        final roomRef = db.collection("chat_rooms").doc();

        transaction.set(roomRef, {
          "users": [uid, strangerId],
          "createdAt": FieldValue.serverTimestamp(),
          "isActive": true,
          "disconnectedBy": null,
        });

        // remove both from waiting
        transaction.delete(strangerRef);
        transaction.delete(myRef);

        print("ROOM CREATED: ${roomRef.id}");
      });

      // ✅ SUCCESS → stop here
      return;
    } catch (e) {
      print("Transaction failed: $e");
      continue;
    }
  }

  // if no match → enter waiting
  print("No match, adding to waiting");

  await waitingRef.doc(uid).set({
    "joinedAt": FieldValue.serverTimestamp(),
    "matched": false,
  });
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
