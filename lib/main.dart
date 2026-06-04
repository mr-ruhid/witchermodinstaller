import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'dart:ui';
import 'screens/loading_screen.dart';
import 'screens/home_screen.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  // 1. QISAYOL İLƏ AÇILDIQDA (MİNİ POP-UP BAŞLATMA)
  if (args.contains('--launch-game')) {
    WindowOptions windowOptions = const WindowOptions(
      size: Size(480, 160), // Ölçünü bir az uyğunlaşdırdıq ki, dizayn qəşəng otursun
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    runApp(const MiniLauncherApp());
    return; // NORMAL BÖYÜK PROQRAMI AÇMAMAQ ÜÇÜN BURADA DAYANDIRIRIQ
  }

  // 2. NORMAL AÇILIŞ (ƏSAS BÖYÜK PROQRAM)
  WindowOptions windowOptions = const WindowOptions(
    size: Size(1280, 720),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.maximize();
  });

  runApp(const ModInstallerApp());
}

// --- NORMAL PROQRAM ---
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
      },
    );
  }
}

// --- MİNİ POP-UP BAŞLADICI (QISAYOL ÜÇÜN AAA DİZAYN) ---
class MiniLauncherApp extends StatefulWidget {
  const MiniLauncherApp({super.key});

  @override
  State<MiniLauncherApp> createState() => _MiniLauncherAppState();
}

class _MiniLauncherAppState extends State<MiniLauncherApp> with SingleTickerProviderStateMixin {
  String statusText = "Sistem yoxlanılır...";
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Nəfəs alan (pulsing) logo animasiyası
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _launchGameDirectly();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _launchGameDirectly() async {
    try {
      // DÜZƏLİŞ 1: Faylın yerini mütləq proqramın (exe) olduğu qovluqdan axtarırıq!
      String baseDir = File(Platform.resolvedExecutable).parent.path;
      final cacheFile = File('$baseDir\\game_path_cache.txt');

      if (await cacheFile.exists()) {
        String gamePath = await cacheFile.readAsString();

        setState(() => statusText = "Oyun faylları tapıldı, başladılır...");
        await Future.delayed(const Duration(milliseconds: 800)); // Animasiya hiss olunsun

        if (await File(gamePath).exists()) {
          String workingDir = File(gamePath).parent.path;

          // Oyunu işə salırıq
          await Process.start(gamePath, [], workingDirectory: workingDir);

          setState(() {
            statusText = "Oyun başladıldı! Uğurlar, Əfsungər!";
          });

          // Oyunu açdıqdan 3.5 saniyə sonra pop-up-ı bağlayırıq
          await Future.delayed(const Duration(milliseconds: 3500));
          exit(0);
        } else {
          setState(() => statusText = "Xəta: Oyun faylı yerində deyil!");
        }
      } else {
        setState(() => statusText = "Xəta: Yol təyin edilməyib. Əsas proqramı açın.");
      }
    } catch (e) {
      setState(() => statusText = "Xəta baş verdi: Xahiş edirik əsas proqramı açın.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: DragToMoveArea(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF100E0C).withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5C07B).withOpacity(0.4), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.9), blurRadius: 30, spreadRadius: 5),
                  ],
                  // Arxa plana yüngülcə oyunun bannerini veririk
                  image: DecorationImage(
                    image: const AssetImage('assets/images/banner.webp'), // Əgər bu yoxdursa home_bg.webp edərsən
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.7), BlendMode.darken),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Sol Tərəf: Nəfəs alan, parlayan Logo
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.redAccent.withOpacity(0.5 * _pulseController.value),
                                  blurRadius: 20 * _pulseController.value,
                                  spreadRadius: 2 * _pulseController.value,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/logohead.webp',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.play_circle_fill_rounded, color: Color(0xFFE5C07B), size: 50),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 20),

                      // Sağ Tərəf: Dinamik Mətnlər və Yüklənmə Çubuğu (DÜZƏLİŞ 2: Overflow həlli üçün Expanded)
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'THE WITCHER 3',
                              style: TextStyle(
                                color: Color(0xFFE5C07B),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'serif',
                                letterSpacing: 2.0,
                              ),
                            ),
                            const Text(
                              'MİLLİ MOD YÜKLƏYİCİ',
                              style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 3.0, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),

                            // Status mətni
                            Text(
                              statusText,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),

                            // İncə və şık yüklənmə çubuğu
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: const LinearProgressIndicator(
                                minHeight: 3,
                                backgroundColor: Colors.white12,
                                color: Colors.greenAccent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}