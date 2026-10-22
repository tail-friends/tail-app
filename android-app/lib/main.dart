import 'package:flutter/material.dart';

void main() {
  runApp(const TailFriendsApp());
}

class TailFriendsApp extends StatelessWidget {
  const TailFriendsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tail Friends',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3D7A57)),
        useMaterial3: true,
      ),
      home: const _ProjectReadyScreen(),
    );
  }
}

class _ProjectReadyScreen extends StatelessWidget {
  const _ProjectReadyScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pets_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                'Tail Friends',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('Android 개발 환경이 준비되었습니다.'),
            ],
          ),
        ),
      ),
    );
  }
}
