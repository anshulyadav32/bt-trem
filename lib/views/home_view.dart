import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Terminal App'),
      ),
      body: const Center(
        child: Text('Welcome to Chat Terminal App!'),
      ),
    );
  }
}
