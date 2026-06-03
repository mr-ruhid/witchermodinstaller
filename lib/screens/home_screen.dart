// Dizayn kökündən dəyişdirildi: Müasir və minimalist AAA Oyun Başladıcısı (Launcher) stili.
// Qabarıq düymələr ləğv edildi, incə və zərif menyu dizaynına keçildi. -- MR-Ruhid
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // Şüşə effekti (BackdropFilter) üçün
import 'dart:io'; // Fayl əməliyyatları (Cache və Process) üçün
import 'package:url_launcher/url_launcher.dart'; // Linkləri açmaq üçün
import 'package:window_manager/window_manager.dart'; // Pəncərə idarəetməsi üçün
import 'package:file_picker/file_picker.dart' as fp; // Toqquşmanın qarşısını almaq üçün "fp" ləqəbi

// Yaratdığımız bütün modları və modeli bura daxil edirik
import '../models/mod_config.dart';
import '../mods/mod1/mod.dart';
import '../mods/mod2/mod.dart';
import '../mods/mod3/mod.dart';
import '../mods/mod4/mod.dart';
import '../mods/mod5/mod.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final List<ModConfig> availableMods = [
    mod1Config,
    mod2Config,
    mod3Config,
    mod4Config,
    mod5Config,
  ];

  final Set<String> selectedModIds = {};

  // Tam ekran alov animasiyası üçün
  late AnimationController _fireController;
  final List<FireParticle> _fireParticles = [];
  final Random _random = Random();

  bool _isLaunchingGame = false;

  @override
  void initState() {
    super.initState();

    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );

    // Qığılcım sayını tam ekran üçün tənzimlədik
    for (int i = 0; i < 120; i++) {
      _fireParticles.add(FireParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.001 + _random.nextDouble() * 0.004,
        size: 1.0 + _random.nextDouble() * 4.0,
        opacity: _random.nextDouble(),
        seed: _random.nextDouble() * 2 * pi,
      ));
    }

    _fireController.addListener(_updateFireParticles);
    _fireController.repeat();
  }

  void _updateFireParticles() {
    for (var particle in _fireParticles) {
      particle.y -= particle.speed;
      particle.x += sin(particle.y * 10 + particle.seed) * 0.001;

      if (particle.y < 0) {
        particle.y = 1.0;
        particle.x = _random.nextDouble();
      }
    }
  }

  @override
  void dispose() {
    _fireController.dispose();
    super.dispose();
  }

  // --- PƏNCƏRƏ (WINDOW) İDARƏETMƏSİ ---
  Future<void> _closeApp() async {
    await windowManager.close();
  }

  Future<void> _minimizeApp() async {
    await windowManager.minimize();
  }

  Future<void> _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // --- OYUNU BAŞLATMA VƏ KEŞ MƏNTİQİ ---
  Future<void> _playGame() async {
    setState(() => _isLaunchingGame = true);

    try {
      final cacheFile = File('game_path_cache.txt');
      String? gamePath;

      if (await cacheFile.exists()) {
        gamePath = await cacheFile.readAsString();
        if (!await File(gamePath).exists()) {
          gamePath = null;
        }
      }

      if (gamePath == null) {
        fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
          dialogTitle: 'Witcher 3 oyununu tapın (witcher3.exe)',
          type: fp.FileType.custom,
          allowedExtensions: ['exe'],
        );

        if (result != null && result.files.single.path != null) {
          String selectedPath = result.files.single.path!;
          if (selectedPath.toLowerCase().endsWith('witcher3.exe')) {
            gamePath = selectedPath;
            await cacheFile.writeAsString(gamePath);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Xəta: Düzgün "witcher3.exe" faylını seçin!'), backgroundColor: Colors.red.shade900),
              );
            }
            return;
          }
        } else {
          return;
        }
      }

      String workingDir = File(gamePath).parent.path;
      await Process.start(gamePath, [], workingDirectory: workingDir);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text('Oyun başladılır... Uğurlar, Əfsungər!'),
              ],
            ),
            backgroundColor: Colors.green.shade800,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xəta: $e'), backgroundColor: Colors.red.shade900),
        );
      }
    } finally {
      if (mounted) setState(() => _isLaunchingGame = false);
    }
  }

  void _toggleModSelection(ModConfig mod) {
    setState(() {
      if (selectedModIds.contains(mod.id)) {
        selectedModIds.remove(mod.id);
      } else {
        if (mod.priority > 0) {
          final modsToRemove = availableMods.where((m) => m.priority == mod.priority && m.id != mod.id).map((m) => m.id).toList();

          if (modsToRemove.any((id) => selectedModIds.contains(id))) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(child: Text('Eyni növdə paketlər eyni anda seçilə bilməz. Əvvəlki seçim ləğv edildi.')),
                  ],
                ),
                backgroundColor: const Color(0xFF8B0000),
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
          for (var id in modsToRemove) selectedModIds.remove(id);
        }

        selectedModIds.add(mod.id);

        if (mod.isLanguagePack) {
          final requiredMods = availableMods.where((m) => m.isRequiredWithLang).map((m) => m.id);
          selectedModIds.addAll(requiredMods);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. TAM EKRAN ARXA PLAN ŞƏKLİ VƏ VİNYETKA
          Positioned.fill(
            child: Image.asset(
              'assets/images/home_bg.webp',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Image.asset('assets/images/banner.webp', fit: BoxFit.cover),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.95), // Sol tərəf (menyu) tam tündləşir
                    Colors.black.withOpacity(0.6),
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),  // Sağ tərəf çox yüngül tünd
                  ],
                  stops: const [0.0, 0.35, 0.7, 1.0],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),

          // 2. TAM EKRAN ALOV/KÜL ANİMASİYASI
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _fireController,
              builder: (context, child) => CustomPaint(painter: FullScreenFirePainter(_fireParticles)),
            ),
          ),

          // 3. ƏSAS MƏZMUN (Müasir Game Launcher Layout: Sol Menyu, Sağ Kontent)
          Positioned.fill(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(child: _buildMainContent()),
              ],
            ),
          ),

          // 4. YUXARI PƏNCƏRƏ İDARƏETMƏ PANELİ (Sürükləmə və Düymələr)
          Positioned(
            top: 0, left: 0, right: 0,
            height: 40,
            child: Row(
              children: [
                Expanded(child: DragToMoveArea(child: Container(color: Colors.transparent))),
                Padding(
                  padding: const EdgeInsets.only(right: 15, top: 10),
                  child: Row(
                    children: [
                      _buildWindowButton(Icons.remove, _minimizeApp, hoverColor: Colors.white24),
                      const SizedBox(width: 8),
                      _buildWindowButton(Icons.close, _closeApp, hoverColor: Colors.redAccent),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SOL İDARƏETMƏ PANELİ (MÜASİR SİDEBAR MENU) ---
  Widget _buildSidebar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30), // Daha güclü şüşə effekti
        child: Container(
          width: 320,
          padding: const EdgeInsets.fromLTRB(25, 50, 25, 25),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.3),
            border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05), width: 1)), // Çox incə sərhəd
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MƏRKƏZDƏ YERLƏŞƏN ƏSAS LOQO
              Center(
                child: Image.asset(
                  'assets/images/logohead.webp',
                  width: 220,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Text('THE WITCHER 3', style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'serif')),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'MİLLİ MOD YÜKLƏYİCİ',
                  style: TextStyle(color: const Color(0xFFE5C07B).withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 4),
                ),
              ),
              const SizedBox(height: 50),

              // OYUNU BAŞLAT MENYUSU (İncə, cəlbedici dizayn)
              _buildMenuButton(
                title: 'OYUNU BAŞLAT',
                icon: Icons.play_arrow_rounded,
                color: Colors.greenAccent,
                isLoading: _isLaunchingGame,
                onTap: _isLaunchingGame ? null : _playGame,
              ),
              const SizedBox(height: 12),

              // SEÇİLƏNLƏRİ QURAŞDIR MENYUSU
              _buildMenuButton(
                title: selectedModIds.isEmpty ? 'MOD SEÇİN' : 'QURAŞDIR (${selectedModIds.length})',
                icon: Icons.download_rounded,
                color: selectedModIds.isEmpty ? Colors.white30 : const Color(0xFFE5C07B),
                isActive: selectedModIds.isNotEmpty,
                onTap: selectedModIds.isEmpty ? null : () => Navigator.pushNamed(context, '/locator', arguments: selectedModIds.toList()),
              ),

              const Spacer(),

              // SOSİAL LİNKLƏR
              Text('BİZİ İZLƏYİN VƏ DƏSTƏK OLUN', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildMiniSocial(Icons.apps_rounded, 'Proqramlar', const Color(0xFFE5C07B), 'https://apps.ruhidjavadov.site'),
                  _buildMiniSocial(Icons.forum_rounded, 'Discord', const Color(0xFF5865F2), 'https://discord.gg/2DZvzyVds'),
                  _buildMiniSocial(Icons.sports_esports_rounded, 'Steam', const Color(0xFF66c0f4), 'https://steamcommunity.com/groups/azegc'),
                  _buildMiniSocial(Icons.local_cafe_rounded, 'Dəstək', const Color(0xFFFF8C00), 'https://kofe.al/tr/@ruhidjavadoff'),
                  _buildMiniSocial(Icons.language_rounded, 'Sayt', Colors.redAccent, 'https://ruhidjavadov.site'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- İNCƏ VƏ MÜASİR MENYU DÜYMƏSİ DİZAYNI ---
  Widget _buildMenuButton({
    required String title,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool isLoading = false,
    bool isActive = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.02) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isActive ? color.withOpacity(0.3) : Colors.white.withOpacity(0.05), width: 1),
          ),
          child: Row(
            children: [
              isLoading
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: color, strokeWidth: 2))
                  : Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.white54,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SAĞ KONTENT (MODLAR) ---
  Widget _buildMainContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    bool hasLanguagePackSelected = availableMods.any((m) => m.isLanguagePack && selectedModIds.contains(m.id));

    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mövcud Modifikasiyalar',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'serif', letterSpacing: 1.2),
          ),
          const SizedBox(height: 25),

          // DİL PAKETİ XƏBƏRDARLIĞI (Daha minimalist)
          if (hasLanguagePackSelected)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFE5C07B).withOpacity(0.05),
                border: Border(left: BorderSide(color: const Color(0xFFE5C07B).withOpacity(0.5), width: 3)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFFE5C07B), size: 22),
                  SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      'Qeyd: Əgər dil paketini yükləyirsinizsə, hərflərin oyunda düzgün görünməsi üçün mütləq ən azı bir font paketi (məsələn, RJ Aze Font) seçili olmalıdır.',
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

          // MOD KARTLARI QRİDİ
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: screenWidth > 1300 ? 3 : (screenWidth > 900 ? 2 : 1),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: screenWidth > 1300 ? 2.5 : 3.0,
              ),
              itemCount: availableMods.length,
              itemBuilder: (context, index) {
                return _buildGlassModCard(availableMods[index], selectedModIds.contains(availableMods[index].id));
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- İNCƏ, ŞÜŞƏ EFFEKTLİ MOD KARTI ---
  Widget _buildGlassModCard(ModConfig mod, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleModSelection(mod),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFE5C07B).withOpacity(0.05) : Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? const Color(0xFFE5C07B).withOpacity(0.5) : Colors.white.withOpacity(0.05), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Kart Loqosu
                  Container(
                    width: 65, height: 65,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        mod.logoPath, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade900, child: const Icon(Icons.extension, color: Colors.white30)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Mətnlər
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                mod.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: isSelected ? const Color(0xFFE5C07B) : Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif'),
                              ),
                            ),
                            if (mod.isBeta)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.redAccent.withOpacity(0.5))),
                                child: const Text('BETA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 1)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Müəllif: ${mod.author}', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 8),
                        Text(
                          mod.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),

                  // İncə Checkbox
                  const SizedBox(width: 12),
                  Theme(
                    data: Theme.of(context).copyWith(
                      unselectedWidgetColor: Colors.white30,
                    ),
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) => _toggleModSelection(mod),
                      activeColor: const Color(0xFFE5C07B),
                      checkColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- MİNİ SOSİAL DÜYMƏLƏR ---
  Widget _buildMiniSocial(IconData icon, String tooltip, Color color, String url) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openUrl(url),
          borderRadius: BorderRadius.circular(8),
          hoverColor: color.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Icon(icon, color: color.withOpacity(0.8), size: 18),
          ),
        ),
      ),
    );
  }

  // Pəncərə düymələri (Bağla, Kiçilt)
  Widget _buildWindowButton(IconData icon, VoidCallback onTap, {required Color hoverColor}) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        hoverColor: hoverColor,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white54, size: 16),
        ),
      ),
    );
  }
}

// --- TAM EKRAN ALOV/KÜL RƏSSAMI ---
class FireParticle {
  double x, y, speed, size, opacity, seed;
  FireParticle({required this.x, required this.y, required this.speed, required this.size, required this.opacity, required this.seed});
}

class FullScreenFirePainter extends CustomPainter {
  final List<FireParticle> particles;
  FullScreenFirePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    for (var particle in particles) {
      paint.shader = RadialGradient(
        colors: [
          Colors.orangeAccent.withOpacity(particle.opacity * 0.6),
          Colors.red.withOpacity(particle.opacity * 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(particle.x * size.width, particle.y * size.height),
        radius: particle.size * 2.0,
      ));
      canvas.drawCircle(Offset(particle.x * size.width, particle.y * size.height), particle.size * 2.0, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}