import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/admin/admin_main_navigation.dart';
import 'screens/user/user_main_navigation.dart';
import 'services/auth_service.dart';
import 'utils/app_theme.dart';
import 'utils/app_state.dart';
import 'services/migration_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await AppState().init();
  await MigrationService.runMigrations();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppState().themeNotifier,
      builder: (context, currentThemeMode, _) {
        return MaterialApp(
          title: "D'Homey Community",
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentThemeMode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

// Widget ini menentukan halaman mana yang muncul saat aplikasi dibuka
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Sedang mengecek status login
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF3D5A80))),
          );
        }

        // Kalau sudah login
        if (snapshot.hasData && snapshot.data != null) {
          // Karena kita butuh cek role dari Firestore (async),
          // kita pakai FutureBuilder
          return FutureBuilder<Map<String, dynamic>?>(
            future: AuthService().getUserData(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Color(0xFF3D5A80))),
                );
              }
              
              if (userSnapshot.hasData && userSnapshot.data != null) {
                final role = userSnapshot.data!['role'];
                if (role == 'admin') {
                  return const AdminMainNavigation();
                } else {
                  return const UserMainNavigation();
                }
              }

              // Kalau gagal ambil role, balik ke welcome
              AuthService().signOut();
              return const WelcomeScreen();
            },
          );
        }

        // Kalau belum login
        return const WelcomeScreen();
      },
    );
  }
}