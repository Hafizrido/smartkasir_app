// Mengimpor pustaka antarmuka Material Design Flutter
import 'package:flutter/material.dart';

// Mengimpor halaman Splash Screen
import 'pages/splash_screen_page.dart';

// Fungsi utama aplikasi
void main() {
  runApp(const SmartKasirApp());
}

// Kelas utama aplikasi
class SmartKasirApp extends StatelessWidget {
  const SmartKasirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartKasir',
      debugShowCheckedModeBanner: false,

      // Pengaturan tema aplikasi
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),

        // Pengaturan AppBar
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
          backgroundColor:  Colors.teal,
          foregroundColor: Colors.white,
        ),
      ),

      // Titik awal aplikasi melalui Splash Screen
      home: const SplashScreenPage(),
    );
  }
}
