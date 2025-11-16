import 'package:flutter/material.dart';
import 'screens/home/home_page.dart';
import 'screens/chat/chat_page.dart';

void main() {
  runApp(const ChatCycleApp());
}

class ChatCycleApp extends StatelessWidget {
  const ChatCycleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/",
      routes: {
        "/": (_) => const HomePage(),
        "/chat": (_) => const ChatPage(),
      },
    );
  }
}
