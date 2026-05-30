import 'package:flutter/material.dart';
import 'dart:async';

class LocatorScreen extends StatefulWidget {
  const LocatorScreen({super.key});

  @override
  State<LocatorScreen> createState() => _LocatorScreenState();
}

class _LocatorScreenState extends State<LocatorScreen> {
  bool _isSearching = true;

  @override
  void initState() {
    super.initState();
    // 4 saniyəlik saxta axtarış prosesi
    Timer(const Duration(seconds: 4), () {
      setState(() {
        _isSearching = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Oyun Axtarılır'),
      ),
      body: Center(
        child: _isSearching
            ? const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Disklər yoxlanılır...\nWitcher 3 qovluğu axtarılır.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Oyun Uğurla Tapıldı!\nC:\\Program Files (x86)\\Steam\\steamapps\\common\\The Witcher 3',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.greenAccent),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                // Ana səhifəyə geri qayıtmaq üçün
                Navigator.pop(context);
              },
              child: const Text('Geri Qayıt'),
            )
          ],
        ),
      ),
    );
  }
}