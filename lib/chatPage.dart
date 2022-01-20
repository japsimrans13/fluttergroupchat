import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'google_signin_helper.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({Key? key}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final textController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Group Chat"),
        leading: IconButton(
          onPressed: () {
            final provider =
                Provider.of<GoogleSignInProvider>(context, listen: false);
            provider.logout();
          },
          icon: const Icon(Icons.logout),
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Text('Welcome ${user!.displayName}, (${user.email})'),
            Expanded(
              child: StreamBuilder<List<Message>>(
                  stream: getMessages(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final messages = snapshot.data!;
                      return ListView(
                        children: messages.map(buildMessageTile).toList(),
                      );
                    } else if (snapshot.hasError) {
                      return const Text('There is an error');
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  }),
            ),
            const Divider(
              thickness: 3.0,
            ),
            TextField(
              controller: textController,
            ),
            ElevatedButton(
                onPressed: () async {
                  if (textController.text != '') {
                    print('work started');

                    createMessage(
                        user.displayName, textController.text, user.email,
                        photoURL: user.photoURL);
                    textController.text = '';
                  }
                },
                child: const Text('Send')),
          ],
        ),
      ),
    );
  }
}

Widget buildMessageTile(Message? message) {
  // If its your message set it towards right side
  final _user = FirebaseAuth.instance.currentUser;
  bool isMessageOwner = false;
  if (message!.email == _user!.email) {
    isMessageOwner = true;
  }

  return ListTile(
    leading: CircleAvatar(
      backgroundImage: NetworkImage(message.photoURL!),
      backgroundColor: Colors.transparent,
    ),
    title: Text(message.message!),
    subtitle: Text(message.displayName!),
    trailing: isMessageOwner
        ? IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              deleteMessage(message.identityNumber);
            },
          )
        : const Spacer(),
    dense: isMessageOwner ? true : false,
    textColor: isMessageOwner ? Colors.black54 : Colors.black,
  );
}

Future createMessage(String? displayName, String? message, String? email,
    {String? photoURL}) async {
  var choiceList = ['a', 'b', 'c', 'd', 'e'];
  final _random = Random();
  var randomElement = choiceList[_random.nextInt(choiceList.length)];
  var messages =
      await FirebaseFirestore.instance.collection('AndroidMessages').get();
  String? newMessageId = (messages.size + 1).toString() + randomElement;
  final messageDocument = FirebaseFirestore.instance
      .collection('AndroidMessages')
      .doc(newMessageId);
  final jsonData = {
    'identityNumber': newMessageId,
    'displayName': displayName,
    'message': message,
    'is_deleted': false,
    'is_public': true,
    'email': email,
    'photoURL': photoURL,
    'createdAt': DateTime.now()
  };
  await messageDocument.set(jsonData);
}

Future deleteMessage(String? identityNumber) async {
  final messageDocument = FirebaseFirestore.instance
      .collection('AndroidMessages')
      .doc(identityNumber)
      .update({"is_deleted": true});
}

Stream<List<Message>> getMessages() => FirebaseFirestore.instance
    .collection('AndroidMessages')
    .where('is_deleted', isEqualTo: false)
    .where('is_public', isEqualTo: true)
    .snapshots()
    .map((snapshot) =>
        snapshot.docs.map((doc) => Message.fromJson(doc.data())).toList());
// print(messages);

class Message {
  String? identityNumber;
  String? displayName;
  String? message;
  String? email;
  String? photoURL;
  // DateTime? createdAt;
  Message(this.identityNumber, this.displayName, this.message, this.email,
      this.photoURL);
  static Message fromJson(Map<String, dynamic> json) => Message(
      json['identityNumber'],
      json['displayName'],
      json['message'],
      json['email'],
      json['photoURL']);
}
