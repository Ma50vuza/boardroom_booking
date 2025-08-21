import 'package:flutter/material.dart';
import 'package:boardroom_booking/services/api_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _isTestingHealth = false;
  bool _isTestingConnectivity = false;
  String? _healthResult;
  String? _connectivityResult;

  Future<void> _testHealth() async {
    setState(() {
      _isTestingHealth = true;
      _healthResult = null;
    });

    try {
      final result = await ApiService.healthCheck();
      setState(() {
        _healthResult = result['success']
            ? 'Server is healthy: ${result['data']}'
            : 'Health check failed: ${result['message']}';
      });
    } catch (e) {
      setState(() {
        _healthResult = 'Health check error: $e';
      });
    }

    setState(() {
      _isTestingHealth = false;
    });
  }

  Future<void> _testConnectivity() async {
    setState(() {
      _isTestingConnectivity = true;
      _connectivityResult = null;
    });

    try {
      final isConnected = await ApiService.testConnectivity();
      setState(() {
        _connectivityResult = isConnected
            ? 'Connectivity test passed!'
            : 'Connectivity test failed!';
      });
    } catch (e) {
      setState(() {
        _connectivityResult = 'Connectivity error: $e';
      });
    }

    setState(() {
      _isTestingConnectivity = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug & Testing'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Server Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Base URL: ${ApiService.baseUrl}'),
                    const SizedBox(height: 8),
                    const Text('Timeout: 30 seconds'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isTestingConnectivity ? null : _testConnectivity,
              icon: _isTestingConnectivity
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi),
              label: const Text('Test Connectivity'),
            ),
            if (_connectivityResult != null) ...[
              const SizedBox(height: 8),
              Card(
                color: _connectivityResult!.contains('passed')
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _connectivityResult!,
                    style: TextStyle(
                      color: _connectivityResult!.contains('passed')
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isTestingHealth ? null : _testHealth,
              icon: _isTestingHealth
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.health_and_safety),
              label: const Text('Test Health Endpoint'),
            ),
            if (_healthResult != null) ...[
              const SizedBox(height: 8),
              Card(
                color: _healthResult!.contains('healthy')
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _healthResult!,
                    style: TextStyle(
                      color: _healthResult!.contains('healthy')
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Common Issues & Solutions:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. Connection Failed:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Check internet connection'),
                    Text('• Verify server is running'),
                    Text('• Check firewall settings'),
                    SizedBox(height: 12),
                    Text(
                      '2. Timeout Errors:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Server may be cold-starting'),
                    Text('• Try again in 30-60 seconds'),
                    Text('• Check server logs for issues'),
                    SizedBox(height: 12),
                    Text(
                      '3. CORS Errors:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('• Check backend CORS settings'),
                    Text('• Verify allowed origins'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
