import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/loading_screen.dart';
import 'screens/home_screen.dart';
import 'screens/locator_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true, // Proqramı həmişə ekranın mərkəzinə alır
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // Çərçivəni gizlədir
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize(); // HƏMİŞƏ TAM EKRAN AÇILIR
  });

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
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.orange,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoadingScreen(),
        '/home': (context) => const HomeScreen(),
        '/locator': (context) => const LocatorScreen(),
      },
    );
  }
}