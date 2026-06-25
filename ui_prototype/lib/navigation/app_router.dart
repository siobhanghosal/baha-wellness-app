import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/prototype_models.dart';
import '../screens/admin/admin_shell.dart';
import '../screens/auth/auth_screens.dart';
import '../screens/parent/parent_shell.dart';
import '../screens/shared/detail_screen.dart';
import '../screens/shared/role_selection_screen.dart';
import '../screens/shared/splash_screen.dart';
import '../screens/student/student_shell.dart';
import '../screens/teacher/teacher_shell.dart';

AppRole _role(String? raw) => AppRole.values
    .firstWhere((r) => r.slug == raw, orElse: () => AppRole.student);

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
        path: '/',
        pageBuilder: (context, state) => _page(const SplashScreen())),
    GoRoute(
        path: '/roles',
        pageBuilder: (context, state) => _page(const RoleSelectionScreen())),
    GoRoute(
        path: '/login/:role',
        pageBuilder: (context, state) =>
            _page(LoginScreen(role: _role(state.pathParameters['role'])))),
    GoRoute(
        path: '/signup/:role',
        pageBuilder: (context, state) =>
            _page(SignupScreen(role: _role(state.pathParameters['role'])))),
    GoRoute(
        path: '/forgot/:role',
        pageBuilder: (context, state) => _page(
            ForgotPasswordScreen(role: _role(state.pathParameters['role'])))),
    GoRoute(
        path: '/otp/:role',
        pageBuilder: (context, state) =>
            _page(OtpScreen(role: _role(state.pathParameters['role'])))),
    GoRoute(
        path: '/onboarding/:role',
        pageBuilder: (context, state) =>
            _page(OnboardingScreen(role: _role(state.pathParameters['role'])))),
    GoRoute(
        path: '/avatar/:role',
        pageBuilder: (context, state) => _page(
            AvatarSelectionScreen(role: _role(state.pathParameters['role'])))),
    GoRoute(
        path: '/student',
        pageBuilder: (context, state) => _page(const StudentShell())),
    GoRoute(
        path: '/parent',
        pageBuilder: (context, state) => _page(const ParentShell())),
    GoRoute(
        path: '/teacher',
        pageBuilder: (context, state) => _page(const TeacherShell())),
    GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => _page(const AdminShell())),
    GoRoute(
        path: '/detail/:role/:title',
        pageBuilder: (context, state) => _page(DetailScreen(
            role: _role(state.pathParameters['role']),
            title: Uri.decodeComponent(
                state.pathParameters['title'] ?? 'Detail')))),
  ],
);

CustomTransitionPage<void> _page(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
          opacity: curved,
          child: SlideTransition(
              position: Tween(begin: const Offset(.04, .02), end: Offset.zero)
                  .animate(curved),
              child: child));
    },
  );
}

String detailPath(AppRole role, String title) =>
    '/detail/${role.slug}/${Uri.encodeComponent(title)}';
String homePath(AppRole role) => switch (role) {
      AppRole.student => '/student',
      AppRole.parent => '/parent',
      AppRole.teacher => '/teacher',
      AppRole.admin => '/admin'
    };
