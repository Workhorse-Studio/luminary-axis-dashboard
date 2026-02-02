library axis_dashboard;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' as auth_ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';
import 'options.dart';

part './pages/dashboard.dart';
part './pages/syllabus.dart';
part './pages/students.dart';
part './pages/teachers.dart';
part './pages/login.dart';
part './pages/student_details.dart';
part './pages/term_details.dart';
part './pages/onboarding_page.dart';
part './pages/dev_screen.dart';

part './components/navbar.dart';
part './components/editable_row.dart';
part './components/protected_page.dart';
part './components/attendance_dialog.dart';
part './components/register_for_class_dialog.dart';
part './components/withdraw_from_class_dialog.dart';
part './components/future_builder_template.dart';

part './design_system/colors.dart';
part './design_system/text_styles.dart';
part './design_system/components/button.dart';
part './design_system/components/card.dart';
part './design_system/components/dropdown_button.dart';
part './design_system/styles.dart';

part './schemas/schemas.dart';
part './schemas/teacher_data.dart';
part './schemas/student_data.dart';
part './schemas/class_data.dart';
part './schemas/archived_attendance_sheet.dart';
part './schemas/global_state.dart';

part './operations/generate_term_report.dart';
part './operations/calculate_teacher_payout.dart';
part './operations/onboard_student.dart';
part './operations/register_class.dart';
part './operations/withdraw_class.dart';
part './operations/reset_term_reports.dart';

part './utils/utils.dart';

part './firebase/firestore.dart';
part './firebase/auth.dart';

late String role = 'admin';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: options);
  try {
    firestore;
    auth;
  } catch (e, st) {
    print(e);
    print(st);
  }
  runApp(const AxisDashboardApp());
}

enum Routes {
  dashboard('/dashboard', 'Dashboard'),
  login('/login', 'Login'),
  syllabus('/syllabus', 'Syllabus'),
  students('/students', 'Students'),
  teachers('/teachers', 'Teachers'),
  termDetails('/termDetails', 'Term Details'),
  onboarding('/onboarding', 'Onboarding'),
  dev('/dev', 'Dev'),
  studentDetails('/studentDetails', 'Student Details')
  ;

  final String slug;
  final String label;
  const Routes(this.slug, this.label);
}

class AxisDashboardApp extends StatefulWidget {
  const AxisDashboardApp({super.key});

  @override
  State<StatefulWidget> createState() => AxisDashboardAppState();
}

class AxisDashboardAppState extends State<AxisDashboardApp> {
  @override
  Widget build(BuildContext context) {
    return TooltipVisibility(
      visible: false,
      child: MaterialApp(
        initialRoute: Routes.login.slug,
        debugShowCheckedModeBanner: false,
        routes: {
          if (kDebugMode) Routes.dev.slug: (_) => const DevScreen(),
          Routes.onboarding.slug: (_) => const OnboardingPage(),
          Routes.dashboard.slug: (_) => ProtectedPage(
            requiredRoles: ['student', 'teacher', 'admin'],
            redirectOnIncorrectRole: Routes.login,
            child: const DashboardPage(),
          ),
          Routes.students.slug: (_) => ProtectedPage(
            requiredRoles: ['teacher', 'admin'],
            redirectOnIncorrectRole: Routes.login,
            child: StudentsPage(),
          ),
          Routes.syllabus.slug: (_) => ProtectedPage(
            requiredRoles: ['teacher'],
            redirectOnIncorrectRole: Routes.login,
            child: SyllabusPage(),
          ),
          Routes.teachers.slug: (_) => ProtectedPage(
            requiredRoles: ['admin'],
            redirectOnIncorrectRole: Routes.login,
            child: const TeachersPage(),
          ),
          Routes.studentDetails.slug: (_) => ProtectedPage(
            requiredRoles: ['admin'],
            redirectOnIncorrectRole: Routes.login,
            child: const StudentDetailsPage(),
          ),
          Routes.termDetails.slug: (_) => ProtectedPage(
            requiredRoles: ['admin'],
            redirectOnIncorrectRole: Routes.login,
            child: const TermDetailsPage(),
          ),
          Routes.login.slug: (_) => LoginPage(),
        },
        theme: ThemeData(
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return AxisColors.blackPurple30.withValues(alpha: 0.35);
                } else if (states.contains(WidgetState.hovered)) {
                  return AxisColors.blackPurple30.withValues(alpha: 0.4);
                } else {
                  return Colors.transparent;
                }
              }),
              iconColor: WidgetStatePropertyAll(
                AxisColors.blackPurple20,
              ),
            ),
          ),
          dropdownMenuTheme: DropdownMenuThemeData(
            inputDecorationTheme: InputDecorationTheme(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: AxisColors.blackPurple20),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(color: AxisColors.blackPurple20),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: AxisColors.blackPurple50,
            shape: Border(
              bottom: BorderSide(color: AxisColors.blackPurple30Blur),
            ),
          ),
        ),
      ),
    );
  }
}
