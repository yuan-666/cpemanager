import 'package:flutter/material.dart';

import 'api/cpe_client.dart';

void main() {
  runApp(const CpeManagerApp());
}

class CpeManagerApp extends StatelessWidget {
  const CpeManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CPE Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff0f766e)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final hostController = TextEditingController(text: '192.168.8.1');
  final usernameController = TextEditingController(text: 'admin');
  final passwordController = TextEditingController();
  String output = 'Ready';
  bool busy = false;

  @override
  void dispose() {
    hostController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> readSnapshot() async {
    setState(() {
      busy = true;
      output = 'Reading...';
    });
    try {
      final client = CpeClient(
        host: hostController.text.trim(),
        username: usernameController.text.trim(),
        password: passwordController.text,
      );
      final snapshot = await client.snapshot();
      setState(() {
        output = snapshot.toString();
      });
    } catch (error) {
      setState(() {
        output = 'Error: $error';
      });
    } finally {
      setState(() {
        busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CPE Manager')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: hostController,
                      decoration: const InputDecoration(labelText: 'Host'),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                  ),
                  FilledButton(
                    onPressed: busy ? null : readSnapshot,
                    child: Text(busy ? 'Reading' : 'Read Snapshot'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(output),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
