import 'package:flutter/material.dart';

import 'src/student_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StudentAppEntryPoint());
}
