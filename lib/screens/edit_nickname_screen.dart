import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EditNicknameScreen extends StatefulWidget {
  const EditNicknameScreen({super.key});

  @override
  State<EditNicknameScreen> createState() => _EditNicknameScreenState();
}

class _EditNicknameScreenState extends State<EditNicknameScreen> {
  final TextEditingController controller = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadCurrentNickname();
  }

  Future<void> loadCurrentNickname() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    if (doc.exists) {
      controller.text = doc.data()?["nickname"] ?? "";
    }

    setState(() {
      loading = false;
    });
  }

  Future<void> saveNickname() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final nickname = controller.text.trim();

    if (nickname.isEmpty) return;

    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      "nickname": nickname,
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff121212),
      appBar: AppBar(
        backgroundColor: Color(0xff121212),
        title: Text("Edit nickname", style: TextStyle(color: Colors.white)),
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: controller,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Nickname",
                      labelStyle: TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: saveNickname,
                      child: Text("Save"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
