import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data'; // ByteData və Uint8List üçün mütləq lazımdır!

// Modellər və locator məlumatları
import '../models/mod_config.dart';
import 'locator_screen.dart';

class InstallDialog extends StatefulWidget {
  final List<ModConfig> selectedMods;
  final GamePaths paths;

  const InstallDialog({super.key, required this.selectedMods, required this.paths});

  // Bu pop-up-ı ekrana çağırmaq üçün xüsusi funksiya
  static Future<void> show(BuildContext context, List<ModConfig> mods, GamePaths paths) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Kopyalama vaxtı kənara basıb bağlamaq olmaz
      builder: (context) => InstallDialog(selectedMods: mods, paths: paths),
    );
  }

  @override
  State<InstallDialog> createState() => _InstallDialogState();
}

class _InstallDialogState extends State<InstallDialog> {
  int _currentIndex = 0;
  double _progress = 0.0;
  bool _isFinished = false;

  // Təhlükəsizlik xətaları və crash qarşılayıcı
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startInstallation();
  }

  // --- MÜKƏMMƏL KOPYALAMA VƏ SETTINGS YAZMA MƏNTİQİ ---
  Future<void> _startInstallation() async {
    try {
      // 1. Aktivlərin (Assets) siyahısını manifestdən YENİ METODLA oxuyuruq
      // JSON XƏTASI BURADA HƏLL OLUNDU!
      final AssetManifest manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final List<String> allAssetKeys = manifest.listAssets();

      for (int i = 0; i < widget.selectedMods.length; i++) {
        if (!mounted) return;

        setState(() {
          _currentIndex = i;
          _progress = 0.0;
        });

        ModConfig currentMod = widget.selectedMods[i];

        // --- ARXA PLANDA HƏQİQİ KOPYALAMA PROSESİ ---
        for (var op in currentMod.operations) {
          if (op.isDirectory) {
            // Virtual qovluq kopyalaması (Sənin axtardığın əsl mod qovluq kopyalaması):
            // Aktivlər içindən bu qovluğa aid olan bütün alt faylları süzürük
            final String dirAssetPath = op.sourceAssetPath;
            final matchedAssets = allAssetKeys.where((key) =>
            key == dirAssetPath ||
                key.startsWith('$dirAssetPath/') ||
                key.startsWith('packages/') && key.contains('/$dirAssetPath/')
            ).toList();

            for (var assetKey in matchedAssets) {
              // Virtual yoldan nisbi yolu hesablayırıq
              int index = assetKey.indexOf(dirAssetPath);
              if (index == -1) continue;

              String relativePart = assetKey.substring(index + dirAssetPath.length);
              if (relativePart.startsWith('/')) {
                relativePart = relativePart.substring(1);
              }

              // Hədəf yolunu yaradırıq (məs: mods/modURW_DinLite/content/blob.bundle)
              String fullTargetPath = '${widget.paths.mainGamePath}/${op.targetGamePath}/$relativePart';
              fullTargetPath = fullTargetPath.replaceAll('/', Platform.pathSeparator).replaceAll('\\', Platform.pathSeparator);

              // Faylın yerləşəcəyi qovluğu yaradırıq
              await Directory(File(fullTargetPath).parent.path).create(recursive: true);

              // Kopyalayırıq
              ByteData data = await rootBundle.load(assetKey);
              List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
              await File(fullTargetPath).writeAsBytes(bytes, flush: true);
            }
          } else {
            // Tək fayl (Məs: Dil paketi en.w3strings) kopyalaması:
            String fullTargetPath;
            if (currentMod.isLanguagePack) {
              // Dil faylını sənin qeyd etdiyin o 3 fərqli content qovluğundan hansı mövcuddursa, ora atırıq
              String contentDirName = 'content0';
              if (Directory('${widget.paths.mainGamePath}/content/content0').existsSync()) {
                contentDirName = 'content0';
              } else if (Directory('${widget.paths.mainGamePath}/content/content').existsSync()) {
                contentDirName = 'content';
              } else if (Directory('${widget.paths.mainGamePath}/content').existsSync()) {
                contentDirName = ''; // Birbaşa content qovluğunun altına
              }

              String subPath = contentDirName.isNotEmpty ? 'content/$contentDirName' : 'content';
              fullTargetPath = '${widget.paths.mainGamePath}/$subPath/${op.targetGamePath}';
            } else {
              fullTargetPath = '${widget.paths.mainGamePath}/${op.targetGamePath}';
            }

            fullTargetPath = fullTargetPath.replaceAll('/', Platform.pathSeparator).replaceAll('\\', Platform.pathSeparator);

            // Qovluğu yaradıb faylı bura kopyalayırıq
            await Directory(File(fullTargetPath).parent.path).create(recursive: true);

            ByteData data = await rootBundle.load(op.sourceAssetPath);
            List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
            await File(fullTargetPath).writeAsBytes(bytes, flush: true);
          }
        }

        // --- SƏNƏDLƏRDƏKİ mods.settings FAYLININ ETİBARLI YENİLƏNMƏSİ ---
        await _updateModsSettings(widget.selectedMods, widget.paths.documentsPath);

        // --- VİZUAL PROQRES ANİMASİYASI (Hiss etdirərək) ---
        for (int p = 1; p <= 100; p++) {
          await Future.delayed(const Duration(milliseconds: 15));
          if (mounted) {
            setState(() {
              _progress = p / 100.0;
            });
          }
        }
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Quraşdırma tam uğurla bitdi
      if (mounted) {
        setState(() {
          _isFinished = true;
        });
      }
    } catch (e) {
      // Əgər kopyalamada hər hansı bir crash ehtimalı olarsa, onu burada tuturuq
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // --- mods.settings PARSER VƏ REBUILDER MƏNTİQİ ---
  Future<void> _updateModsSettings(List<ModConfig> selectedMods, String docsPath) async {
    final settingsFile = File('$docsPath/mods.settings'.replaceAll('/', Platform.pathSeparator));
    String content = '';

    if (await settingsFile.exists()) {
      content = await settingsFile.readAsString();
    } else {
      await settingsFile.create(recursive: true);
    }

    // Mövcud məlumatları saxlayaraq INI formatında parse edirik (mükəmməl parser)
    Map<String, Map<String, String>> sections = {};
    List<String> lines = content.split('\n');
    String currentSection = '';

    for (var line in lines) {
      line = line.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('[') && line.endsWith(']')) {
        currentSection = line.substring(1, line.length - 1);
        sections[currentSection] = {};
      } else if (currentSection.isNotEmpty && line.contains('=')) {
        var parts = line.split('=');
        String key = parts[0].trim();
        String val = parts.sublist(1).join('=').trim();
        sections[currentSection]![key] = val;
      }
    }

    // Bizim seçdiyimiz modları Enabled=1 və öz prioritetləri ilə siyahıya əlavə/yenilə edirik
    for (var mod in selectedMods) {
      for (var op in mod.operations) {
        if (op.targetGamePath.startsWith('mods/')) {
          String modFolderName = op.targetGamePath.replaceFirst('mods/', '');
          sections[modFolderName] = {
            'Enabled': '1',
            'Priority': '${mod.priority}',
          };
        }
      }
    }

    // INI faylını sıfırdan səliqəli şəkildə yenidən qurub yazırıq
    StringBuffer sb = StringBuffer();
    sections.forEach((section, keys) {
      sb.writeln('[$section]');
      keys.forEach((key, val) {
        sb.writeln('$key=$val');
      });
      sb.writeln(); // Bölmələr arası boş sətir
    });

    await settingsFile.writeAsString(sb.toString(), flush: true);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedMods.isEmpty) return const SizedBox();

    final currentMod = widget.selectedMods[_currentIndex];
    final int percentage = (_progress * 100).toInt();

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF151210).withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasError ? Colors.redAccent : const Color(0xFFE5C07B).withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _hasError ? Colors.red.withOpacity(0.15) : Colors.black.withOpacity(0.8),
                  blurRadius: 20,
                  spreadRadius: 5,
                )
              ],
            ),
            child: _hasError ? _buildErrorUi() : _buildInstallUi(currentMod, percentage),
          ),
        ),
      ),
    );
  }

  // --- XƏTA (PERMİSSİON/CRASH) EKRANI ---
  Widget _buildErrorUi() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.gpp_bad_rounded, color: Colors.redAccent, size: 36),
            SizedBox(width: 12),
            Text(
              'QURAŞDIRILMA DAYANDIRILDI!',
              style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontFamily: 'serif'),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const Divider(color: Colors.white10),
        const SizedBox(height: 15),
        const Text(
          'Giriş rədd edildi və ya kopyalama xətası baş verdi. Windows oyun fayllarını dəyişdirməyə icazə vermir.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Sistem xətası: $_errorMessage',
          style: const TextStyle(color: Colors.white38, fontSize: 11, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: const Text(
            'HƏLLİ: Zəhmət olmasa bu proqramı bağlayın, üzərində sağ klikləyin və "Yönetici olarak çalıştır" (Run as Administrator) seçərək yenidən açın.',
            style: TextStyle(color: Colors.redAccent, fontSize: 13, height: 1.4, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 25),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900),
            child: const Text('PROQRAMI BAĞLA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // --- NORMAL QURAŞDIRMA EKRANI ---
  Widget _buildInstallUi(ModConfig currentMod, int percentage) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isFinished ? 'QURAŞDIRMA BİTDİ' : 'QURAŞDIRILIR...',
          style: const TextStyle(color: Color(0xFFE5C07B), fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2.0),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5)],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  currentMod.logoPath, fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade900, child: const Icon(Icons.extension, color: Colors.white30)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentMod.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'serif'),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    currentMod.description,
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isFinished ? 'Milli paketlər quraşdırıldı!' : 'Paket ${(_currentIndex + 1)} / ${widget.selectedMods.length}',
                  style: TextStyle(color: _isFinished ? Colors.greenAccent : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(_isFinished ? '100%' : '$percentage%', style: const TextStyle(color: Color(0xFFE5C07B), fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: _isFinished ? 1.0 : _progress,
                minHeight: 8,
                backgroundColor: Colors.black.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(_isFinished ? Colors.greenAccent : const Color(0xFF8B0000)),
              ),
            ),
          ],
        ),
        if (_isFinished) ...[
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  side: const BorderSide(color: Colors.white30),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('GERİ QAYIT', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.greenAccent),
                label: const Text('BİTİR VƏ BAŞLAT', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B2A18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: Colors.green.shade800),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}