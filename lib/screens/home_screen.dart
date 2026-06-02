// Bütün dəyişikliklər Witcher dizaynına uyğunlaşdırılmış, şüşə/su damcısı effekti və kart dizaynı tətbiq edilmişdir. -- MR-Ruhid
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui'; // Şüşə effekti (BackdropFilter) üçün
import 'dart:io'; // Fayl əməliyyatları (Cache və Process) üçün
import 'package:url_launcher/url_launcher.dart'; // Linkləri açmaq üçün
import 'package:window_manager/window_manager.dart'; // Pəncərə idarəetməsi üçün əlavə olundu
import 'package:file_picker/file_picker.dart'; // Oyun faylını seçmək üçün

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
  // Bütün modlarımızın siyahısı
  final List<ModConfig> availableMods = [
    mod1Config,
    mod2Config,
    mod3Config,
    mod4Config,
    mod5Config,
  ];

  final Set<String> selectedModIds = {};

  // Bannerdəki alov animasiyası üçün
  late AnimationController _fireController;
  final List<FireParticle> _fireParticles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _fireController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    );

    // Daha realistik qığılcımlar üçün seed əlavə olundu
    for (int i = 0; i < 70; i++) {
      _fireParticles.add(FireParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: 0.002 + _random.nextDouble() * 0.005, // Sürət daha realistik tənzimləndi
        size: 1.0 + _random.nextDouble() * 3.5,
        opacity: _random.nextDouble(),
        seed: _random.nextDouble() * 2 * pi, // Dalğalanma üçün fərqli başlanğıc nöqtəsi
      ));
    }

    _fireController.addListener(_updateFireParticles);
    _fireController.repeat();
  }

  void _updateFireParticles() {
    for (var particle in _fireParticles) {
      particle.y -= particle.speed;
      // Qığılcımların kül kimi dalğalanması (Smooth wave effect)
      particle.x += sin(particle.y * 15 + particle.seed) * 0.0015;

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

  // --- PƏNCƏRƏ (WINDOW) İDARƏETMƏ FUNKSİYALARI ---
  Future<void> _closeApp() async {
    await windowManager.close();
  }

  Future<void> _minimizeApp() async {
    await windowManager.minimize();
  }

  // Linkləri açmaq üçün funksiya
  Future<void> _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // --- OYUNU BAŞLATMA VƏ KEŞ (CACHE) MƏNTİQİ ---
  Future<void> _playGame() async {
    final cacheFile = File('game_path_cache.txt');
    String? gamePath;

    // 1. Fayl (Keş) yoxlanılır
    if (await cacheFile.exists()) {
      gamePath = await cacheFile.readAsString();
      // Yoxlayırıq görək fayl həqiqətən ordadırmı (istifadəçi silmiş və ya yerini dəyişmiş ola bilər)
      if (!await File(gamePath).exists()) {
        gamePath = null;
      }
    }

    // 2. Keşdə yoxdursa, File Picker açılır
    if (gamePath == null) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Witcher 3 oyununu tapın (witcher3.exe)',
        type: FileType.custom,
        allowedExtensions: ['exe'],
      );

      if (result != null && result.files.single.path != null) {
        String selectedPath = result.files.single.path!;
        // Seçilən faylın witcher3.exe olduğundan əmin oluruq
        if (selectedPath.toLowerCase().endsWith('witcher3.exe')) {
          gamePath = selectedPath;
          // Gələcək istifadələr üçün yolu keşə yazırıq
          await cacheFile.writeAsString(gamePath);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Xəta: Zəhmət olmasa düzgün "witcher3.exe" faylını seçin!'),
                backgroundColor: Colors.red.shade900,
              ),
            );
          }
          return;
        }
      } else {
        return; // İstifadəçi pəncərəni bağladısa əməliyyatı dayandır
      }
    }

    // 3. Oyunu başladırıq
    try {
      String workingDir = File(gamePath).parent.path; // Oyunun düzgün işləməsi üçün qovluğu götürürük
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Oyunu başlatmaq mümkün olmadı: $e'),
            backgroundColor: Colors.red.shade900,
          ),
        );
      }
    }
  }

  // Mod seçilmə məntiqi (Priority / Toqquşma yoxlanışı)
  void _toggleModSelection(ModConfig mod) {
    setState(() {
      if (selectedModIds.contains(mod.id)) {
        selectedModIds.remove(mod.id);
      } else {
        if (mod.priority > 0) {
          final modsToRemove = availableMods
              .where((m) => m.priority == mod.priority && m.id != mod.id)
              .map((m) => m.id)
              .toList();

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
                backgroundColor: const Color(0xFF8B0000), // Qan qırmızısı
                duration: const Duration(seconds: 3),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }

          for (var id in modsToRemove) {
            selectedModIds.remove(id);
          }
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
    final screenWidth = MediaQuery.of(context).size.width;
    bool hasLanguagePackSelected = availableMods.any((m) => m.isLanguagePack && selectedModIds.contains(m.id));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F12),
              Color(0xFF181513),
              Color(0xFF100E0C),
            ],
          ),
        ),
        child: Column(
          children: [
            // --- YUXARI BANNER HİSSƏSİ ---
            _buildBanner(),

            // --- SOSİAL LİNKLƏR VƏ DİGƏR PROQRAMLAR ---
            _buildSocialCards(),

            // --- DİL PAKETİ ÜÇÜN XƏBƏRDARLIQ ---
            if (hasLanguagePackSelected)
              Container(
                margin: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFFE5C07B).withOpacity(0.15), Colors.transparent],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: const Border(left: BorderSide(color: Color(0xFFE5C07B), width: 4)),
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(8), bottomRight: Radius.circular(8)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFFE5C07B), size: 28),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'Qeyd: Əgər dil paketini yükləyirsinizsə, hərflərin oyunda düzgün görünməsi üçün mütləq ən azı bir font paketi (məsələn, RJ Aze Font) seçili olmalıdır.',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

            // --- MODLAR SİYAHISI (GRID/KART FORMASINDA) ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: screenWidth > 1200 ? 4 : (screenWidth > 800 ? 3 : (screenWidth > 600 ? 2 : 1)),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: screenWidth > 600 ? 2.5 : 3.0,
                  ),
                  itemCount: availableMods.length,
                  itemBuilder: (context, index) {
                    final mod = availableMods[index];
                    final isSelected = selectedModIds.contains(mod.id);

                    return _buildModCard(mod, isSelected);
                  },
                ),
              ),
            ),

            // --- AŞAĞI: OYUNU BAŞLAT VƏ QURAŞDIR DÜYMƏLƏRİ ---
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner() {
    return ClipRect(
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
            border: const Border(bottom: BorderSide(color: Color(0xFFE5C07B), width: 2)),
            boxShadow: [
              BoxShadow(color: const Color(0xFFE5C07B).withOpacity(0.1), blurRadius: 20, spreadRadius: 2, offset: const Offset(0, 5))
            ]
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/banner.webp',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stackTrace) => Container(color: Colors.brown.shade900),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.95),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: AnimatedBuilder(
                animation: _fireController,
                builder: (context, child) {
                  return CustomPaint(
                    painter: BannerFirePainter(_fireParticles),
                  );
                },
              ),
            ),
            const Align(
              alignment: Alignment.center,
              child: Text(
                'Witcher Mod Yükləyici',
                style: TextStyle(
                  color: Color(0xFFE5C07B),
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'serif',
                  letterSpacing: 2.5,
                  shadows: [
                    Shadow(color: Colors.redAccent, blurRadius: 20),
                    Shadow(color: Colors.orange, blurRadius: 10),
                    Shadow(color: Colors.black, blurRadius: 15, offset: Offset(3, 3)),
                  ],
                ),
              ),
            ),

            // --- XÜSUSİ PƏNCƏRƏ İDARƏETMƏ DÜYMƏLƏRİ (SADƏCƏ KİÇİLT VƏ BAĞLA) ---
            Positioned(
              top: 15,
              right: 15,
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
    );
  }

  // Pəncərə düymələrinin xüsusi Witcher tərzi dizaynı
  Widget _buildWindowButton(IconData icon, VoidCallback onTap, {required Color hoverColor}) {
    return Material(
      color: Colors.black.withOpacity(0.6),
      shape: const CircleBorder(),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        hoverColor: hoverColor,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white24, width: 1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white70, size: 18),
        ),
      ),
    );
  }

  Widget _buildSocialCards() {
    return Container(
      width: double.infinity,
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151210),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildGlassCard(
            title: 'Digər Proqramlar',
            icon: Icons.apps_rounded,
            color: const Color(0xFFE5C07B),
            url: 'https://apps.ruhidjavadov.site',
            isPremium: true,
          ),
          _buildGlassCard(
            title: 'Discord',
            icon: Icons.forum_rounded,
            color: const Color(0xFF5865F2),
            url: 'https://discord.gg/2DZvzyVds',
          ),
          _buildGlassCard(
            title: 'Steam Topluluğu',
            icon: Icons.sports_esports_rounded,
            color: const Color(0xFF66c0f4),
            url: 'https://steamcommunity.com/groups/azegc',
          ),
          _buildGlassCard(
            title: 'Oyunu Al (Steam)',
            icon: Icons.store_rounded,
            color: Colors.tealAccent,
            url: 'https://store.steampowered.com/app/292030/The_Witcher_3_Wild_Hunt/',
          ),
          _buildGlassCard(
            title: 'Dəstək Ol',
            icon: Icons.local_cafe_rounded,
            color: const Color(0xFFFF8C00),
            url: 'https://kofe.al/tr/@ruhidjavadoff',
          ),
          _buildGlassCard(
            title: 'Saytımız',
            icon: Icons.language_rounded,
            color: Colors.redAccent,
            url: 'https://ruhidjavadov.site',
          ),
          _buildGlassCard(
            title: 'GitHub',
            icon: Icons.code_rounded,
            color: Colors.grey.shade400,
            url: 'https://github.com/mr-ruhid',
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required String title, required IconData icon, required Color color, required String url, bool isPremium = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openUrl(url),
          borderRadius: BorderRadius.circular(15),
          splashColor: color.withOpacity(0.3),
          highlightColor: color.withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isPremium ? color : Colors.white12, width: isPremium ? 1.5 : 1),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.15),
                  Colors.white.withOpacity(0.02),
                ],
              ),
              boxShadow: isPremium ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, spreadRadius: 1)] : [],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 5)],
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      title,
                      style: TextStyle(
                        color: isPremium ? color : Colors.white70,
                        fontWeight: isPremium ? FontWeight.bold : FontWeight.w500,
                        fontSize: 14,
                        fontFamily: isPremium ? 'serif' : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModCard(ModConfig mod, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleModSelection(mod),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          // Fərqli Premium Qradiyent arxa planı
          gradient: LinearGradient(
            colors: isSelected
                ? [const Color(0xFF382315), const Color(0xFF1E1510)]
                : [const Color(0xFF221F1E), const Color(0xFF151210)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFE5C07B) : Colors.white12,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFFE5C07B).withOpacity(0.25), blurRadius: 15, spreadRadius: 2)]
              : [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Loqo Dizaynı
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 6, offset: const Offset(2, 2))],
                  border: Border.all(color: Colors.white12, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    mod.logoPath,
                    width: 65,
                    height: 65,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 65,
                      height: 65,
                      color: Colors.grey.shade900,
                      child: const Icon(Icons.extension, color: Colors.white30),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Mətnlər hissəsi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mod.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFFE5C07B) : Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                              shadows: isSelected ? [const Shadow(color: Colors.black, blurRadius: 5)] : [],
                            ),
                          ),
                        ),
                        if (mod.isBeta)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF8B0000), Color(0xFFB71C1C)]),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 4)],
                            ),
                            child: const Text(
                              'BETA',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Müəllif: ${mod.author}',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mod.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Checkbox Dizaynı
              Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFE5C07B).withOpacity(0.1) : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) => _toggleModSelection(mod),
                  activeColor: const Color(0xFFE5C07B),
                  checkColor: Colors.black,
                  side: const BorderSide(color: Colors.white54, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFF100E0C),
        border: const Border(top: BorderSide(color: Colors.white12, width: 1)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          // OYUNU BAŞLAT DÜYMƏSİ
          Expanded(
            flex: 2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B2A18), Color(0xFF0F170D)], // Tünd qədimi yaşıl/meşə rəngi
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [BoxShadow(color: Colors.greenAccent.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)],
                border: Border.all(color: Colors.green.shade800, width: 1.5),
              ),
              child: ElevatedButton(
                onPressed: _playGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.greenAccent,
                      size: 28,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'OYUNU BAŞLAT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.greenAccent,
                        fontFamily: 'serif',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // QURAŞDIR DÜYMƏSİ
          Expanded(
            flex: 3,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: selectedModIds.isEmpty
                    ? LinearGradient(colors: [Colors.grey.shade900, Colors.grey.shade900])
                    : const LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFF5C0000)], // Qan qırmızısı qradiyenti
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: selectedModIds.isEmpty
                    ? []
                    : [BoxShadow(color: const Color(0xFF8B0000).withOpacity(0.5), blurRadius: 15, spreadRadius: 2)],
                border: Border.all(
                  color: selectedModIds.isEmpty ? Colors.white12 : const Color(0xFFE5C07B).withOpacity(0.7),
                  width: 1.5,
                ),
              ),
              child: ElevatedButton(
                onPressed: selectedModIds.isEmpty
                    ? null
                    : () {
                  Navigator.pushNamed(context, '/locator', arguments: selectedModIds.toList());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.download_rounded,
                      color: selectedModIds.isEmpty ? Colors.white30 : const Color(0xFFE5C07B),
                      size: 26,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedModIds.isEmpty ? 'Ən az bir mod seçin' : 'Seçilənləri Quraşdır (${selectedModIds.length})',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: selectedModIds.isEmpty ? Colors.white54 : const Color(0xFFE5C07B),
                        fontFamily: 'serif',
                        letterSpacing: 1.2,
                        shadows: selectedModIds.isEmpty ? [] : [const Shadow(color: Colors.black, blurRadius: 5)],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FireParticle {
  double x;
  double y;
  double speed;
  double size;
  double opacity;
  double seed;

  FireParticle({required this.x, required this.y, required this.speed, required this.size, required this.opacity, required this.seed});
}

class BannerFirePainter extends CustomPainter {
  final List<FireParticle> particles;

  BannerFirePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      paint.shader = RadialGradient(
        colors: [
          Colors.orangeAccent.withOpacity(particle.opacity * 0.9),
          Colors.red.withOpacity(particle.opacity * 0.5),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(particle.x * size.width, particle.y * size.height),
        radius: particle.size * 1.8,
      ));

      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size * 1.8,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}