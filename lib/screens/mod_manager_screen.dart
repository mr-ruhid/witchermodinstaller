import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:archive/archive.dart';

class CustomModInfo {
  final String name;
  bool enabled;
  int priority;

  CustomModInfo({required this.name, required this.enabled, required this.priority});
}

class ModManagerScreen extends StatefulWidget {
  const ModManagerScreen({super.key});

  @override
  State<ModManagerScreen> createState() => _ModManagerScreenState();
}

class _ModManagerScreenState extends State<ModManagerScreen> {
  List<CustomModInfo> _installedMods = [];
  String? _gamePath;
  String? _docsPath;
  bool _isLoading = true;
  bool _isInstalling = false;
  String _installStatus = '';

  @override
  void initState() {
    super.initState();
    _initManager();
  }

  // --- 1. YOLLARI VƏ SETTINGS FAYLINI OXUYURUQ ---
  Future<void> _initManager() async {
    setState(() => _isLoading = true);
    try {
      final cacheFile = File('game_paths_cache.json');
      if (await cacheFile.exists()) {
        final data = jsonDecode(await cacheFile.readAsString());
        _gamePath = data['gamePath'];
        _docsPath = data['docsPath'];

        if (_docsPath != null) {
          await _loadModsSettings();
        }
      }
    } catch (e) {
      debugPrint('Paths load error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadModsSettings() async {
    if (_docsPath == null) return;
    final settingsFile = File('$_docsPath/mods.settings'.replaceAll('/', Platform.pathSeparator));

    if (!await settingsFile.exists()) {
      _installedMods = [];
      return;
    }

    String content = await settingsFile.readAsString();
    List<String> lines = content.split('\n');

    List<CustomModInfo> parsedMods = [];
    String currentModName = '';
    bool currentEnabled = false;
    int currentPriority = 0;

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('[') && line.endsWith(']')) {
        // Əvvəlki modu siyahıya əlavə edirik
        if (currentModName.isNotEmpty) {
          parsedMods.add(CustomModInfo(name: currentModName, enabled: currentEnabled, priority: currentPriority));
        }
        // Yeni moda keçirik
        currentModName = line.substring(1, line.length - 1);
        currentEnabled = false;
        currentPriority = 0;
      } else if (currentModName.isNotEmpty && line.contains('=')) {
        var parts = line.split('=');
        String key = parts[0].trim();
        String val = parts.sublist(1).join('=').trim();

        if (key == 'Enabled') currentEnabled = val == '1';
        if (key == 'Priority') currentPriority = int.tryParse(val) ?? 0;
      }
    }

    // Sonuncu modu da əlavə edirik
    if (currentModName.isNotEmpty) {
      parsedMods.add(CustomModInfo(name: currentModName, enabled: currentEnabled, priority: currentPriority));
    }

    setState(() {
      _installedMods = parsedMods;
    });
  }

  // --- 2. SETTINGS FAYLINA YENİDƏN YAZMAQ (GÜNCƏLLƏMƏK) ---
  Future<void> _saveModsSettings() async {
    if (_docsPath == null) return;
    final settingsFile = File('$_docsPath/mods.settings'.replaceAll('/', Platform.pathSeparator));

    StringBuffer sb = StringBuffer();
    for (var mod in _installedMods) {
      sb.writeln('[${mod.name}]');
      sb.writeln('Enabled=${mod.enabled ? 1 : 0}');
      sb.writeln('Priority=${mod.priority}');
      sb.writeln(); // Boş sətir
    }

    await settingsFile.writeAsString(sb.toString(), flush: true);
  }

  // --- 3. KƏNAR ARXİVDƏN (ZIP, RAR, 7Z) YENİ MOD QURAŞDIRMAQ ---
  Future<void> _installNewMod() async {
    if (_gamePath == null || _docsPath == null) {
      _showSnackBar('Əvvəlcə Ana Səhifədən yolları təsdiqləyin (Oyun və Sənədlər qovluğunu tapın).', Colors.redAccent);
      return;
    }

    fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
      dialogTitle: 'Quraşdırmaq istədiyiniz Modu seçin (.zip, .rar, .7z)',
      type: fp.FileType.custom,
      allowedExtensions: ['zip', 'rar', '7z'], // ARTIQ RAR VƏ 7Z DƏ QƏBUL EDİLİR
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      String extension = filePath.split('.').last.toLowerCase();

      setState(() {
        _isInstalling = true;
        _installStatus = 'Arxiv faylı analiz edilir...';
      });

      try {
        bool modFound = false;
        String foundModName = '';

        if (extension == 'zip') {
          // --- ZIP FAYLLARI ÜÇÜN DAXİLİ SÜRƏTLİ DART MƏNTİQİ ---
          File zipFile = File(filePath);
          List<int> bytes = await zipFile.readAsBytes();
          Archive archive = ZipDecoder().decodeBytes(bytes);

          RegExp modFolderRegex = RegExp(r'(?:^|/)(mod[^/]+)/(.*)', caseSensitive: false);

          for (ArchiveFile file in archive) {
            if (file.isFile && !file.name.endsWith('/')) {
              Match? match = modFolderRegex.firstMatch(file.name);
              if (match != null) {
                modFound = true;
                foundModName = match.group(1)!;
                String relativePathInsideMod = match.group(2)!;

                String fullTargetPath = '$_gamePath/mods/$foundModName/$relativePathInsideMod';
                fullTargetPath = fullTargetPath.replaceAll('/', Platform.pathSeparator).replaceAll('\\', Platform.pathSeparator);

                await Directory(File(fullTargetPath).parent.path).create(recursive: true);
                await File(fullTargetPath).writeAsBytes(file.content as List<int>, flush: true);
              }
            }
          }
        } else if (extension == 'rar' || extension == '7z') {
          // --- RAR VƏ 7Z FAYLLARI ÜÇÜN 7Z.EXE MƏNTİQİ ---
          String baseDir = File(Platform.resolvedExecutable).parent.path;

          // Yeni təyin etdiyin yol: assets/7z/7z.exe
          String exePath = '$baseDir\\data\\flutter_assets\\assets\\7z\\7z.exe';
          if (!File(exePath).existsSync()) {
            exePath = '${Directory.current.path}\\assets\\7z\\7z.exe';
          }

          if (!File(exePath).existsSync()) {
            throw Exception('XƏTA: .rar və .7z arxivlərini açmaq üçün "7z.exe" tapılmadı! Faylların layihənizin "assets/7z/" qovluğunda olduğuna əmin olun.');
          }

          // Arxa planda müvəqqəti qovluq (Temp) yaradırıq
          String tempPath = '${Directory.systemTemp.path}\\WitcherModTemp_${DateTime.now().millisecondsSinceEpoch}';
          await Directory(tempPath).create(recursive: true);

          // 7z.exe ilə arxivi gizlicə Temp qovluğuna çıxarırıq (-y əmri hər şeyə avtomatik "Yes" deyir)
          var process = await Process.run(exePath, ['x', filePath, '-o$tempPath', '-y']);
          if (process.exitCode != 0) {
            throw Exception('Arxivi çıxarmaq mümkün olmadı. Fayl zədəli ola bilər və ya 7z.dll faylı əskikdir.');
          }

          // Çıxarılan qovluqlarda "mod..." adında qovluq axtarırıq
          await for (var entity in Directory(tempPath).list(recursive: true)) {
            if (entity is Directory) {
              String dirName = entity.path.split(Platform.pathSeparator).last;
              if (dirName.toLowerCase().startsWith('mod') && dirName.length > 3) {
                modFound = true;
                foundModName = dirName;

                // Tapılan modu oyunun mods qovluğuna kopyalayırıq
                String targetDir = '$_gamePath/mods/$foundModName'.replaceAll('/', Platform.pathSeparator);
                await _copyDirectory(entity, Directory(targetDir));
                break; // İlk mod qovluğunu tapanda dayanır
              }
            }
          }

          // İşimiz bitdikdən sonra kompüterdə yer tutmasın deyə müvəqqəti qovluğu silirik
          try { await Directory(tempPath).delete(recursive: true); } catch(_) {}
        }

        // Qovluq kopyalandısa Settings-ə yazırıq
        if (modFound) {
          bool exists = false;
          for (var mod in _installedMods) {
            if (mod.name.toLowerCase() == foundModName.toLowerCase()) {
              mod.enabled = true;
              exists = true;
              break;
            }
          }

          if (!exists) {
            _installedMods.add(CustomModInfo(name: foundModName, enabled: true, priority: 1));
          }

          await _saveModsSettings();
          _showSnackBar('$foundModName uğurla quraşdırıldı!', Colors.greenAccent);
        } else {
          _showSnackBar('XƏTA: Bu arxivin içində "mod..." adlı qovluq tapılmadı. Bu düzgün mod olmaya bilər.', Colors.redAccent);
        }

      } catch (e) {
        _showSnackBar('Quraşdırma xətası: $e', Colors.redAccent);
      } finally {
        setState(() {
          _isInstalling = false;
        });
      }
    }
  }

  // Dart dilində standart qovluq kopyalama funksiyası olmadığı üçün özümüz yaradırıq
  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (var entity in source.list(recursive: false)) {
      if (entity is Directory) {
        var newDirectory = Directory('${destination.absolute.path}\\${entity.path.split(Platform.pathSeparator).last}');
        await newDirectory.create();
        await _copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        await entity.copy('${destination.absolute.path}\\${entity.path.split(Platform.pathSeparator).last}');
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)), backgroundColor: color.withOpacity(0.9)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: const Text('MOD İDARƏEDİCİSİ', style: TextStyle(color: Color(0xFFE5C07B), fontFamily: 'serif', fontWeight: FontWeight.bold, letterSpacing: 2.0)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE5C07B)))
          : Stack(
        children: [
          // Arxa plan effekti
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset('assets/images/home_bg.webp', fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox()),
            ),
          ),

          Column(
            children: [
              // 1. DAİMİ XƏBƏRDARLIQ (CRASH VƏ PRİORİTET)
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B0000).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 36),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'DİQQƏT: Əgər oyun başlarkən Crash (Xəta) verirsə, bu modların bir-biri ilə toqquşmasından ola bilər! Belə halda buraya gələrək şübhələndiyiniz modları "Deaktiv" edin və ya "Prioritet (Priority)" dəyərlərini dəyişdirərək oyunu yenidən yoxlayın. (Prioriteti yüksək olan rəqəm, məs: 1, digərlərini əzir və birinci oxunur).',
                        style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. YENİ MOD YÜKLƏ DÜYMƏSİ VƏ BAŞLIQ
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('YÜKLÜ MODLARIN SİYAHISI', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ElevatedButton.icon(
                      onPressed: _isInstalling ? null : _installNewMod,
                      icon: _isInstalling
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                          : const Icon(Icons.add_circle_outline_rounded, color: Colors.black),
                      label: Text(_isInstalling ? _installStatus : 'KƏNAR MOD YÜKLƏ (.ZIP)', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5C07B),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // 3. MODLARIN SİYAHISI
              Expanded(
                child: _installedMods.isEmpty
                    ? Center(child: Text('Hələ heç bir mod quraşdırılmayıb (mods.settings boşdur).', style: TextStyle(color: Colors.white.withOpacity(0.5))))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _installedMods.length,
                  itemBuilder: (context, index) {
                    final mod = _installedMods[index];
                    return _buildModItem(mod);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MOD KARTININ VİZUAL DİZAYNI ---
  Widget _buildModItem(CustomModInfo mod) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: mod.enabled ? Colors.greenAccent.withOpacity(0.05) : Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mod.enabled ? Colors.greenAccent.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // İşarə
          Icon(Icons.folder_zip_rounded, color: mod.enabled ? const Color(0xFFE5C07B) : Colors.white30, size: 30),
          const SizedBox(width: 16),

          // Mod Adı
          Expanded(
            child: Text(
              mod.name,
              style: TextStyle(
                color: mod.enabled ? Colors.white : Colors.white54,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace', // Proqramlaşdırma/Mod adı stili
              ),
            ),
          ),

          // Prioritet İdarəetməsi
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Priority (Prioritet)', style: TextStyle(color: Colors.white54, fontSize: 10)),
              const SizedBox(height: 4),
              Row(
                children: [
                  _buildMiniBtn(Icons.remove, () {
                    if (mod.priority > 0) {
                      setState(() => mod.priority--);
                      _saveModsSettings();
                    }
                  }),
                  Container(
                    width: 35,
                    alignment: Alignment.center,
                    child: Text('${mod.priority}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  _buildMiniBtn(Icons.add, () {
                    setState(() => mod.priority++);
                    _saveModsSettings();
                  }),
                ],
              ),
            ],
          ),

          const SizedBox(width: 30),

          // Aktiv/Deaktiv Switç
          Column(
            children: [
              Text(mod.enabled ? 'AKTİVDİR' : 'DEAKTİV', style: TextStyle(color: mod.enabled ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              Switch(
                value: mod.enabled,
                activeColor: Colors.greenAccent,
                inactiveThumbColor: Colors.redAccent,
                inactiveTrackColor: Colors.redAccent.withOpacity(0.2),
                onChanged: (val) {
                  setState(() => mod.enabled = val);
                  _saveModsSettings();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Prioritet artırıb/azaltmaq üçün mini düymə
  Widget _buildMiniBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}