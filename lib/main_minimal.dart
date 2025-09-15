import 'package:flutter/material.dart';

void main() {
  runApp(const MinimalTestApp());
}

class MinimalTestApp extends StatelessWidget {
  const MinimalTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Minimal iOS Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MinimalHomePage(),
    );
  }
}

class MinimalHomePage extends StatelessWidget {
  const MinimalHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minimal iOS Test'),
        backgroundColor: Colors.blue,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Hello iOS!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'This is a minimal Flutter app to test iOS rendering.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Button pressed!')),
          );
        },
        tooltip: 'Test Button',
        child: const Icon(Icons.add),
      ),
    );
  }
}
