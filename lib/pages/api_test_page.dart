
import 'package:flutter/material.dart';
import 'api_service.dart';

class ApiTestPage extends StatefulWidget {
  const ApiTestPage({super.key});

  @override
  State<ApiTestPage> createState() => _ApiTestPageState();
}

class _ApiTestPageState extends State<ApiTestPage> {
  String result = 'Not tested yet';
  bool loading = false;

  Future<void> testApi() async {
    setState(() {
      loading = true;
      result = 'Connecting to FixMate API...';
    });

    try {
      final data = await ApiService.checkHealth();

      if (!mounted) return;

      setState(() {
        result = 'Connection successful!\n'
            'Response: ${data['status']}';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        result = 'Connection failed:\n$e';
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FixMate API Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(result, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: loading ? null : testApi,
                child: Text(
                  loading ? 'Testing...' : 'Test API Connection',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
