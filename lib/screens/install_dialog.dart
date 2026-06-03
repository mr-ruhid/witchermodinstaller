import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import '../models/mod_config.dart';

class InstallDialog extends StatefulWidget {
  final List<ModConfig> selectedMods;

  const InstallDialog({super.key, required this.selectedMods});

  // Bu pop-up-ı rahat çağırmaq üçün funksiya
  static Future<void> show(BuildContext context, List<ModConfig> mods) {
    return showDialog(
      context: context,
      barrierDismissible: false, // Yüklənmə vaxtı kənara basıb bağlamaq olmasın
      builder: (context) => InstallDialog(selectedMods: mods),
    );
  }

  @override
  State<InstallDialog> createState() => _InstallDialogState();
}

class _InstallDialogState extends State<InstallDialog> {
  int _currentIndex = 0;
  double _progress = 0.0;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    // Pəncərə açılanda quraşdırmanı avtomatik başlat
    _startInstallation();
  }

  Future<void> _startInstallation() async {
    // Hər bir seçilmiş mod üçün dövr edirik
    for (int i = 0; i < widget.selectedMods.length; i++) {
      if (!mounted) return;

      setState(() {
        _currentIndex = i;
        _progress = 0.0;
      });

      // Modun konfiqurasiyası (fayl yolu və s.)
      // ModConfig currentMod = widget.selectedMods[i];

      // --- ƏSL KOPYALAMA VƏ mods.settings MƏNTİQİ BURADA YAZILACAQ ---
      // (Növbəti addımda buranı gerçək kodlarla əvəz edəcəyik)

      // --- VİZUAL YÜKLƏNMƏ GÖZLƏMƏSİ (3.5 Saniyə) ---
      // 100 addımdan ibarət dövr, hər addım 35 millisaniyə çəkir (Cəmi ~3.5 saniyə)
      for (int p = 1; p <= 100; p++) {
        await Future.delayed(const Duration(milliseconds: 35));
        if (mounted) {
          setState(() {
            _progress = p / 100.0;
          });
        }
      }

      // Hər paket arası kiçik yarım saniyəlik fasilə
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Bütün modlar bitdi
    if (mounted) {
      setState(() {
        _isFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Əgər siyahı boşdursa xəta verməmək üçün təhlükəsizlik
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
              color: const Color(0xFF151210).withOpacity(0.9), // Tünd Witcher fonu
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5C07B).withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 20, spreadRadius: 5)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlıq
                Text(
                  _isFinished ? 'QURAŞDIRMA BİTDİ' : 'QURAŞDIRILIR...',
                  style: const TextStyle(
                    color: Color(0xFFE5C07B),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 20),

                // Mod Məlumatları (Loqo + Ad/Açıqlama)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Loqo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24, width: 1),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 5)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          currentMod.logoPath,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey.shade900,
                            child: const Icon(Icons.extension, color: Colors.white30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Ad və Açıqlama
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentMod.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            currentMod.description,
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Yüklənmə Barı (Progress Bar)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isFinished
                              ? 'Bütün paketlər uğurla quruldu!'
                              : 'Paket ${(_currentIndex + 1)} / ${widget.selectedMods.length}',
                          style: TextStyle(
                            color: _isFinished ? Colors.greenAccent : Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _isFinished ? '100%' : '$percentage%',
                          style: const TextStyle(color: Color(0xFFE5C07B), fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Barın özü
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _isFinished ? 1.0 : _progress,
                        minHeight: 8,
                        backgroundColor: Colors.black.withOpacity(0.5),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isFinished ? Colors.greenAccent : const Color(0xFF8B0000), // Quraşdırılanda qırmızı, bitəndə yaşıl
                        ),
                      ),
                    ),
                  ],
                ),

                // Bitdikdə Görünən Düymələr
                if (_isFinished) ...[
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Pop-up-ı bağlayır
                          Navigator.pop(context);
                        },
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
                        onPressed: () {
                          Navigator.pop(context);
                          // Burada birbaşa oyunu başladan funksiyanı çağıra bilərik
                          // Amma hələlik istifadəçini Home-a qaytarıb orada "Oyunu Başlat"a basdıracağıq.
                        },
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
            ),
          ),
        ),
      ),
    );
  }
}