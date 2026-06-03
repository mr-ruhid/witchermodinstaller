import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';

class DonateDialog extends StatefulWidget {
  const DonateDialog({super.key});

  // Pəncərəni çağırmaq üçün statik metod
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // 5 saniyəlik məcburi olduğu üçün kənara basanda bağlanmır
      builder: (context) => const DonateDialog(),
    );
  }

  @override
  State<DonateDialog> createState() => _DonateDialogState();
}

class _DonateDialogState extends State<DonateDialog> {
  int _secondsRemaining = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _openUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _copyToClipboard(String text, String platformName) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$platformName adresi kopyalandı!', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: 550,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF151210).withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5C07B).withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 30, spreadRadius: 5),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başlıq və İkon
                const Icon(Icons.volunteer_activism_rounded, color: Color(0xFFE5C07B), size: 48),
                const SizedBox(height: 15),
                const Text(
                  'LAYİHƏYƏ DƏSTƏK OLUN',
                  style: TextStyle(
                    color: Color(0xFFE5C07B),
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'serif',
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Bu layihə tamamilə ödənişsizdir. Əgər əməyimizi qiymətləndirirsinizsə və gələcək yeniliklərin davamlı olmasını istəyirsinizsə, bizə motivasiya üçün dəstək ola bilərsiniz!',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                // Linklər (Çay/Kofe)
                Row(
                  children: [
                    Expanded(child: _buildLinkButton('Kofe.al', Icons.local_cafe_rounded, Colors.orangeAccent, () => _openUrl('https://kofe.al/ruhidjavadoff'))),
                    const SizedBox(width: 15),
                    Expanded(child: _buildLinkButton('Çayvoy', Icons.emoji_food_beverage_rounded, Colors.tealAccent, () => _openUrl('https://cayvoy.com/donate/ruhid4715'))),
                  ],
                ),
                const SizedBox(height: 15),

                // Kopyalanan Adreslər (PayPal / Crypto)
                _buildCopyButton('PayPal Dəstəyi', 'ruhidjavadoff@gmail.com', Icons.paypal_rounded, Colors.blueAccent),
                const SizedBox(height: 10),
                _buildCopyButton('Crypto (USDT - BNB Smart Chain)', '0x9a4AD41762D6B07B8C266b312Cf0dBe31FAd890c', Icons.currency_bitcoin_rounded, Colors.amber),

                const SizedBox(height: 30),

                // Geri Sayım və Bağlama Düyməsi
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: _secondsRemaining == 0 ? () => Navigator.pop(context) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B2A18),
                      disabledBackgroundColor: Colors.white.withOpacity(0.05),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: _secondsRemaining == 0 ? Colors.greenAccent.withOpacity(0.5) : Colors.transparent),
                    ),
                    child: Text(
                      _secondsRemaining > 0 ? 'PƏNCƏRƏ BAĞLANIR... ($_secondsRemaining)' : 'TƏŞƏKKÜRLƏR, BAĞLA',
                      style: TextStyle(
                        color: _secondsRemaining == 0 ? Colors.greenAccent : Colors.white54,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyButton(String title, String address, IconData icon, Color color) {
    return InkWell(
      onTap: () => _copyToClipboard(address, title),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(address, style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, color: Colors.white30, size: 20),
          ],
        ),
      ),
    );
  }
}