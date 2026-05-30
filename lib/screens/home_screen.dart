import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Səhifə'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.games, size: 80, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              'Witcher 3 Mod Yükləyiciyə Xoş Gəlmisiniz!',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // Oyun axtarış səhifəsinə keçid
                Navigator.pushNamed(context, '/locator');
              },
              icon: const Icon(Icons.search),
              label: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Oyunu Tap', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}