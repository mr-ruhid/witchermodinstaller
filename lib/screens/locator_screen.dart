import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async'; // Əlavə olundu: Ağıllı axtarış və Streamlər üçün
import 'package:file_picker/file_picker.dart' as fp;

class GamePaths {
  final String mainGamePath;
  final String documentsPath;

  GamePaths({required this.mainGamePath, required this.documentsPath});
}

class LocatorScreen extends StatefulWidget {
  final String? initialGamePath;
  final String? initialDocsPath;

  const LocatorScreen({super.key, this.initialGamePath, this.initialDocsPath});

  static Future<GamePaths?> show(BuildContext context, {String? gamePath, String? docsPath}) {
    return showDialog<GamePaths>(
      context: context,
      barrierDismissible: false,
      builder: (context) => LocatorScreen(initialGamePath: gamePath, initialDocsPath: docsPath),
    );
  }

  @override
  State<LocatorScreen> createState() => _LocatorScreenState();
}

class _LocatorScreenState extends State<LocatorScreen> {
  String? _gamePath;
  String? _docsPath;

  bool _isGamePathValid = false;
  bool _isDocsPathValid = false;

  bool _isDeepSearching = false; // Ağıllı axtarışın fırlanma animasiyası üçün

  // Xətaları xüsusi göstərmək üçün dəyişənlər
  String? _gamePermissionError;
  String? _docsPermissionError;

  @override
  void initState() {
    super.initState();
    _gamePath = widget.initialGamePath;
    _docsPath = widget.initialDocsPath;

    _autoDetectPaths(); // Pəncərə açılan kimi avtomatik axtarış işə düşür
  }

  // --- 1. AVTOMATİK (SÜRƏTLİ) AXTARIŞ ---
  Future<void> _autoDetectPaths() async {
    if (_docsPath == null || _docsPath!.isEmpty) {
      String userProfile = Platform.environment['USERPROFILE'] ?? '';
      String potentialDocs = '$userProfile\\Documents\\The Witcher 3';

      if (Directory(potentialDocs).existsSync()) {
        _docsPath = potentialDocs;
      }
    }

    if (_gamePath == null || _gamePath!.isEmpty) {
      List<String> commonPaths = [
        r'C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3',
        r'C:\SteamLibrary\steamapps\common\The Witcher 3',
        r'D:\SteamLibrary\steamapps\common\The Witcher 3',
        r'E:\SteamLibrary\steamapps\common\The Witcher 3',
        r'F:\SteamLibrary\steamapps\common\The Witcher 3',
      ];

      for (String path in commonPaths) {
        if (File('$path\\bin\\x64\\witcher3.exe').existsSync()) {
          _gamePath = path;
          break;
        }
      }
    }

    _validatePaths();
  }

  // --- 2. YOLLARIN DƏRİN VƏ TƏHLÜKƏSİZLİK (İCAZƏ) YOXLANILMASI ---
  void _validatePaths() {
    setState(() {
      // 1. Əsas oyun qovluğunun yoxlanılması
      _isGamePathValid = false;
      _gamePermissionError = null;

      if (_gamePath != null && _gamePath!.isNotEmpty) {
        File exeFile = File('$_gamePath\\bin\\x64\\witcher3.exe');

        Directory content0Dir = Directory('$_gamePath\\content\\content0');
        Directory contentDir = Directory('$_gamePath\\content\\content');
        Directory baseContentDir = Directory('$_gamePath\\content');

        bool hasValidContentDir = content0Dir.existsSync() || contentDir.existsSync() || baseContentDir.existsSync();

        if (exeFile.existsSync() && hasValidContentDir) {
          // --- CRASH QARŞISINI ALAN İCAZƏ YOXLANILMASI ---
          try {
            File temp = File('$_gamePath\\mod_installer_permission_test.tmp');
            temp.writeAsStringSync('test'); // Yaza bilirsə icazə var
            temp.deleteSync(); // Sınaq faylını silirik
            _isGamePathValid = true; // Hər şey əladır
          } catch (e) {
            _gamePermissionError = 'QOVLUĞA YAZMA İCAZƏSİ YOXDUR!\nCrash-in qarşısı alındı.\nZəhmət olmasa proqramı bağlayın və "Administrator" olaraq işə salın.';
          }
        }
      }

      // 2. Sənədlər (Documents) qovluğunun yoxlanılması
      _isDocsPathValid = false;
      _docsPermissionError = null;

      if (_docsPath != null && _docsPath!.isNotEmpty) {
        Directory docsDir = Directory(_docsPath!);
        if (docsDir.existsSync() && _docsPath!.endsWith('The Witcher 3')) {
          try {
            File temp = File('$_docsPath\\mod_installer_permission_test.tmp');
            temp.writeAsStringSync('test');
            temp.deleteSync();
            _isDocsPathValid = true;
          } catch (e) {
            _docsPermissionError = 'QOVLUĞA YAZMA İCAZƏSİ YOXDUR!\nProqramı "Administrator" kimi açın.';
          }
        }
      }
    });
  }

  // --- 3. DƏRİN AXTARIŞ (AĞILLI SKAN - CRASH-PROOF) ---
  Future<void> _deepSearchGamePath() async {
    String? selectedDir = await fp.FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Oyunun yerləşdiyi Diski və ya Qovluğu seçin (Məsələn: C:\\)',
    );

    if (selectedDir != null) {
      setState(() => _isDeepSearching = true);

      try {
        Directory rootDir = Directory(selectedDir);
        bool found = false;

        var completer = Completer<void>();
        var subscription = rootDir.list(recursive: true, followLinks: false).listen(
              (entity) {
            if (!found && entity is File && entity.path.toLowerCase().endsWith('witcher3.exe')) {
              found = true;
              Directory mainDir = entity.parent.parent.parent;
              setState(() {
                _gamePath = mainDir.path;
              });
            }
          },
          onError: (e) {
            // Sistem qovluqlarına girəndə olan xətaları uduruq ki, proqram crash verməsin
          },
          onDone: () {
            if (!completer.isCompleted) completer.complete();
          },
          cancelOnError: false,
        );

        Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (found) {
            subscription.cancel();
            if (!completer.isCompleted) completer.complete();
            timer.cancel();
          }
        });

        await completer.future;

        if (found) {
          _validatePaths();
        } else {
          _showError('Seçdiyiniz qovluqda oyun tapılmadı!');
        }
      } catch (e) {
        _showError('Axtarış zamanı xəta baş verdi. Daha kiçik qovluq seçin.');
      } finally {
        setState(() => _isDeepSearching = false);
      }
    }
  }

  // --- MANUAL "OYUN QOVLUĞUNU" SEÇMƏK (YENİLƏNDİ) ---
  Future<void> _pickGamePath() async {
    String? selectedDir = await fp.FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Oyunun əsas qovluğunu seçin (Məsələn: .../common/The Witcher 3)',
    );

    if (selectedDir != null) {
      // İstifadəçi qovluğu seçdikdən sonra həmin qovluğun içində
      // doğrudan da witcher3.exe-nin olub-olmadığını yoxlayırıq.
      File exeCheck = File('$selectedDir\\bin\\x64\\witcher3.exe');

      if (exeCheck.existsSync()) {
        setState(() {
          _gamePath = selectedDir;
        });
        _validatePaths();
      } else {
        _showError('Seçdiyiniz qovluqda oyun tapılmadı! Doğru qovluğu seçdiyinizdən əmin olun.');
      }
    }
  }

  // --- SƏNƏDLƏR (DOCS) QOVLUĞUNU SEÇMƏK ---
  Future<void> _pickDocsPath() async {
    String? result = await fp.FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Sənədlərinizdəki "The Witcher 3" qovluğunu seçin',
    );

    if (result != null) {
      if (result.endsWith('The Witcher 3') || result.endsWith('The Witcher 3\\')) {
        setState(() {
          _docsPath = result;
        });
        _validatePaths();
      } else {
        _showError('Seçdiyiniz qovluq "The Witcher 3" sənədlər (Documents) qovluğu deyil!');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.red.shade900,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmSelection() {
    if (_isGamePathValid && _isDocsPathValid) {
      Navigator.of(context).pop(GamePaths(mainGamePath: _gamePath!, documentsPath: _docsPath!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: const Color(0xFF100E0C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5C07B).withOpacity(0.5), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 30, spreadRadius: 10)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAŞLIQ
            const Row(
              children: [
                Icon(Icons.rule_folder_rounded, color: Color(0xFFE5C07B), size: 36),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    'SİSTEM YOLLARININ YOXLANILMASI',
                    style: TextStyle(
                      color: Color(0xFFE5C07B),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'serif',
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              'Modların qüsursuz işləməsi üçün yollar təsdiqlənməlidir. Sistem avtomatik axtarış apardı. Əgər yollar səhvdirsə (və ya qırmızı ❌ işarəsi varsa), onları manual seçin və ya "Ağıllı Axtarış"dan istifadə edin.',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 30),

            // 1. ƏSAS OYUN QOVLUĞU KARTI
            _buildPathCard(
              title: 'Əsas Oyun Qovluğu (SteamLibrary)',
              description: 'İçində "bin" və "content" qovluqları olan əsas qovluqdur.',
              path: _gamePath,
              isValid: _isGamePathValid,
              isSearching: _isDeepSearching,
              permissionError: _gamePermissionError,
              btnText: 'QOVLUQ SEÇ', // DÜYMƏ MƏTNİ DƏYİŞDİRİLDİ
              onTap: _pickGamePath,
              onSmartSearchTap: _deepSearchGamePath,
            ),
            const SizedBox(height: 20),

            // 2. SƏNƏDLƏR QOVLUĞU KARTI
            _buildPathCard(
              title: 'Sənədlər (Documents) Qovluğu',
              description: 'Modların oyunda aktivləşdirilməsi üçün "mods.settings" faylı buraya yazılacaq.',
              path: _docsPath,
              isValid: _isDocsPathValid,
              isSearching: false,
              permissionError: _docsPermissionError,
              btnText: 'QOVLUQ SEÇ',
              onTap: _pickDocsPath,
            ),
            const SizedBox(height: 35),

            // DÜYMƏLƏR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white54, size: 20),
                  label: const Text('İMTİNA ET VƏ QAYIT', style: TextStyle(color: Colors.white54, letterSpacing: 1)),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: (_isGamePathValid && _isDocsPathValid)
                        ? [BoxShadow(color: Colors.greenAccent.withOpacity(0.2), blurRadius: 15)]
                        : [],
                  ),
                  child: ElevatedButton(
                    onPressed: (_isGamePathValid && _isDocsPathValid && !_isDeepSearching) ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2A18),
                      disabledBackgroundColor: Colors.white.withOpacity(0.05),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(
                        color: (_isGamePathValid && _isDocsPathValid) ? Colors.greenAccent.withOpacity(0.5) : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      'TƏSDİQLƏ VƏ QURAŞDIR',
                      style: TextStyle(
                        color: (_isGamePathValid && _isDocsPathValid) ? Colors.greenAccent : Colors.white30,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Yenilənmiş Kart dizaynı
  Widget _buildPathCard({
    required String title,
    required String description,
    required String? path,
    required bool isValid,
    required bool isSearching,
    required String btnText,
    required VoidCallback onTap,
    String? permissionError,
    VoidCallback? onSmartSearchTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isValid ? Colors.greenAccent.withOpacity(0.05) : Colors.redAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isValid ? Colors.greenAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isSearching
                ? const CircularProgressIndicator(color: Color(0xFFE5C07B))
                : Icon(
              isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
              key: ValueKey<bool>(isValid),
              color: isValid ? Colors.greenAccent : Colors.redAccent,
              size: 40,
              shadows: [BoxShadow(color: (isValid ? Colors.greenAccent : Colors.redAccent).withOpacity(0.5), blurRadius: 10)],
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    isSearching
                        ? 'Qovluqlar dərindən axtarılır, zəhmət olmasa gözləyin...'
                        : (permissionError != null ? permissionError : (path != null && path.isNotEmpty ? path : 'Yol tapılmadı və ya seçilməyib...')),
                    style: TextStyle(
                      color: isSearching ? const Color(0xFFE5C07B) : (isValid ? Colors.greenAccent : Colors.redAccent.shade200),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          Column(
            children: [
              if (onSmartSearchTap != null && !isValid) ...[
                ElevatedButton.icon(
                  onPressed: isSearching ? null : onSmartSearchTap,
                  icon: const Icon(Icons.saved_search_rounded, size: 16),
                  label: const Text('AĞILLI AXTARIŞ', style: TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(height: 6),
              ],
              ElevatedButton(
                onPressed: isSearching ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(btnText, style: const TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}