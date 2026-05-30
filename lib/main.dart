import 'package:flutter/material.dart';
import 'screens/loading_screen.dart';
import 'screens/home_screen.dart';
import 'screens/locator_screen.dart';

void main() {
  runApp(const ModInstallerApp());
}

class ModInstallerApp extends StatelessWidget {
  const ModInstallerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Witcher 3 Mod Yükləyici',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark, // Oyun proqramlarına uyğun tünd tema
        colorSchemeSeed: Colors.orange, // Witcher temasına uyğun narıncı rənglər
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        // Səhifələrin yolları (routes) burada təyin olunur
        '/': (context) => const LoadingScreen(),
        '/home': (context) => const HomeScreen(),
        '/locator': (context) => const LocatorScreen(),
      },
    );
  }
}