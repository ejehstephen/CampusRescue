import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/main_shell.dart';
import 'state/emergency_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CampusRescueApp());
}

class CampusRescueApp extends StatelessWidget {
  const CampusRescueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => EmergencyState())],
      child: MaterialApp(
        title: 'CampusRescue - Campus Emergency System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        onGenerateRoute: (settings) {
          final uri = Uri.parse(settings.name ?? '/');
          int initialIndex = 0;
          bool isDirectRoute = false;

          if (uri.path == '/dispatch' || uri.path == '/dispatcher') {
            initialIndex = 1;
            isDirectRoute = true;
          } else if (uri.path == '/responder' || uri.path == '/patrol') {
            initialIndex = 2;
            isDirectRoute = true;
          } else if (uri.path == '/report') {
            initialIndex = 0;
            isDirectRoute = true;
          }

          return MaterialPageRoute(
            builder: (_) => MainShell(
              initialIndex: initialIndex,
              isDirectRoute: isDirectRoute,
            ),
            settings: settings,
          );
        },
      ),
    );
  }
}
