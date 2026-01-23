library digistore;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as auth_ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'options.dart';

part 'pages/dashboard.dart';
part 'pages/syllabus.dart';
part 'pages/login.dart';

part './components/navbar.dart';
part './components/protected_page.dart';

part './firebase/firestore.dart';
part './firebase/auth.dart';

String? wing;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: options);

  runApp(const DigistoreApp());
}

enum Routes {
  dashboard('/'),
  login('/login'),
  syllabus('/syllabus'),
  students('/students'),
  teachers('/teachers');

  final String slug;
  const Routes(this.slug);
}

class DigistoreApp extends StatefulWidget {
  const DigistoreApp({super.key});

  @override
  State<StatefulWidget> createState() => DigistoreAppState();
}

class DigistoreAppState extends State<DigistoreApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: Routes.dashboard.slug,
      routes: {
        Routes.dashboard.slug: (_) => DashboardPage(),
        Routes.syllabus.slug: (_) => ProtectedPage(child: SyllabusPage()),
        Routes.login.slug: (_) => LoginPage(),
      },
    );
  }
}
