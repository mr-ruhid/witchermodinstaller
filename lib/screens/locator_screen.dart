import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart' as fp;

// Bu sinif tapılan yolları Home səhifəsinə geri qaytarmaq üçün bir modeldir
class GamePaths {
  final String mainGamePath; // Məs: C:\Program Files (x86)\Steam\steamapps\common\The Witcher 3
  final String documentsPath; // Məs: C:\Users\Admin\Documents\The Witcher 3

  GamePaths({required this.mainGamePath, required this.documentsPath});
}

class LocatorDialog extends StatefulWidget {
  final String missingType; // "main" (Oyun tapılmadı) və ya "docs" (Sənədlər tapılmadı)

  const LocatorDialog({super.key, required this.missingType});

  // Bu funksiya pop-up-ı ekrana çağırmaq üçün rahat bir yoldur
  static Future<GamePaths?> show(BuildContext context, {required String missingType}) {
    return showDialog<GamePaths>(
      context: context,
      barrierDismissible: false, // Kənara basıb bağlamaq olmaz
      builder: (context) => LocatorDialog(missingType: missingType),
    );
  }

  @override
  State<LocatorDialog> createState() => _LocatorDialogState();
}

class _LocatorDialogState extends State<LocatorDialog> {
  String? _selectedPath;
  bool _isError = false;

  Future<void> _pickPath() async {
    setState(() => _isError = false);

    // Əgər əsas oyun qovluğu axtarılırsa, witcher3.exe faylını seçdiririk ki, tam dəqiq yeri tapaq
    if (widget.missingType == 'main') {
      fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
        dialogTitle: 'Witcher 3 oyununu tapın (bin\\x64\\witcher3.exe)',
        type: fp.FileType.custom,
        allowedExtensions: ['exe'],
      );

      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;
        // Seçilən faylın "witcher3.exe" olub-olmadığını yoxlayırıq
        if (path.toLowerCase().endsWith('witcher3.exe')) {
          // witcher3.exe adətən "The Witcher 3\bin\x64\witcher3.exe" içində olur
          // Bizə əsas oyun qovluğu lazımdır, ona görə də bir neçə addım geriyə (parent) gedirik
          File exeFile = File(path);
          Directory binDir = exeFile.parent; // x64 qovluğu
          Directory parentDir = binDir.parent; // bin qovluğu
          Directory mainDir = parentDir.parent; // The Witcher 3 qovluğu (bizə lazım olan)

          setState(() {
            _selectedPath = mainDir.path;
          });
        } else {
          setState(() => _isError = true);
        }
      }
    }
    // Əgər Documents/Sənədlər qovluğu axtarılırsa, birbaşa qovluq (Directory) seçdiririk
    else {
      String? result = await fp.FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Sənədlərinizdəki "The Witcher 3" qovluğunu seçin',
      );

      if (result != null) {
        // Doğrudan da o qovluğun adının "The Witcher 3" olub-olmadığını və ya içində
        // gamesaves, mods.settings olub-olmadığını yoxlaya bilərik
        if (result.endsWith('The Witcher 3') || result.endsWith('The Witcher 3\\')) {
          setState(() {
            _selectedPath = result;
          });
        } else {
          setState(() => _isError = true);
        }
      }
    }
  }

  void _confirmSelection() {
    if (_selectedPath != null) {
      if (widget.missingType == 'main') {
        // İkinci parametri (documentsPath) hələlik boş göndəririk, Home səhifəsi hər ikisini yığacaq
        Navigator.of(context).pop(GamePaths(mainGamePath: _selectedPath!, documentsPath: ''));
      } else {
        Navigator.of(context).pop(GamePaths(mainGamePath: '', documentsPath: _selectedPath!));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMain = widget.missingType == 'main';
    String title = isMain ? 'Oyun Qovluğu Tapılmadı' : 'Sənədlər Qovluğu Tapılmadı';
    String description = isMain
        ? 'Sistem "The Witcher 3" oyununun avtomatik quraşdırma yerini tapa bilmədi. Zəhmət olmasa "witcher3.exe" faylını manual olaraq seçin.'
        : 'Sistem "Documents/The Witcher 3" qovluğunu tapa bilmədi (Bu qovluq modların oyunda aktiv olması üçün şərtdir). Zəhmət olmasa qovluğu manual olaraq seçin.';
    IconData icon = isMain ? Icons.folder_off_rounded : Icons.snippet_folder_rounded;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151210), // Witcher tünd fon
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B0000), width: 2), // Qırmızı xəbərdarlıq sərhədi
          boxShadow: [
            BoxShadow(color: const Color(0xFF8B0000).withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlıq və İkon
            Row(
              children: [
                Icon(icon, color: const Color(0xFFE5C07B), size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFE5C07B),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Colors.white12, thickness: 1),
            const SizedBox(height: 16),

            // Açıqlama
            Text(
              description,
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),

            // Seçilən yolun göstərilməsi (və ya Xəta)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _isError ? Colors.redAccent : Colors.white24, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isError
                          ? (isMain ? 'XƏTA: Seçilən fayl "witcher3.exe" deyil!' : 'XƏTA: Seçilən qovluq "The Witcher 3" sənədlər qovluğu deyil!')
                          : (_selectedPath ?? 'Heç bir yer seçilməyib...'),
                      style: TextStyle(
                        color: _isError ? Colors.redAccent : (_selectedPath != null ? Colors.greenAccent : Colors.white54),
                        fontSize: 13,
                        fontStyle: _selectedPath == null && !_isError ? FontStyle.italic : FontStyle.normal,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _pickPath,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5C07B),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('SEÇ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Düymələr (İmtina və Təsdiq)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(), // Heç nə qaytarmadan bağlayır
                  child: const Text('İMTİNA', style: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _selectedPath != null ? _confirmSelection : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B2A18),
                    disabledBackgroundColor: Colors.black.withOpacity(0.3),
                    side: BorderSide(color: _selectedPath != null ? Colors.greenAccent : Colors.transparent),
                  ),
                  child: Text(
                    'TƏSDİQLƏ',
                    style: TextStyle(color: _selectedPath != null ? Colors.greenAccent : Colors.white30, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}