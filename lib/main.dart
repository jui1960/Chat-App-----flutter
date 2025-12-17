// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'screens/login_screen.dart';
import 'package:chat_app/screens/home_screen.dart';
// NEW: UserStatusTracker ইমপোর্ট করুন
import 'screens//user_status_tracker.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 1. Load the saved theme preference before running the app
  final savedThemeMode = await ThemeNotifier.loadThemeMode();

  // NEW: স্ট্যাটাস ট্র্যাকার ইনিশিয়ালাইজ করুন
  // এটি প্রথম ইউজার লগইন হওয়ার সাথে সাথেই কাজ শুরু করবে
  UserStatusTracker();

  runApp(
    ChangeNotifierProvider(
      // 2. Initialize ThemeNotifier with the loaded theme mode
      create: (_) => ThemeNotifier(savedThemeMode),
      child: ChatApp(),
    ),
  );
}

class ChatApp extends StatelessWidget {
// ... (Rest of the ChatApp code remains unchanged)
// ...
// ...
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Chat App',
      themeMode: themeNotifier.themeMode,
      theme: ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF0F5F8),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF0F5F8), elevation: 0, iconTheme: IconThemeData(color: Colors.black)),
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: Colors.lightBlueAccent, surface: Colors.white),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black),
            bodyMedium: TextStyle(color: Colors.black87),
            bodySmall: TextStyle(color: Colors.grey),
          )
      ),
      darkTheme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF141A23),
          appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF141A23), elevation: 0, iconTheme: IconThemeData(color: Colors.white)),
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: Colors.lightBlueAccent, surface: const Color(0xFF1E2733), brightness: Brightness.dark),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
            bodySmall: TextStyle(color: Colors.grey),
          )
      ),
      home: FirebaseAuth.instance.currentUser != null
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}