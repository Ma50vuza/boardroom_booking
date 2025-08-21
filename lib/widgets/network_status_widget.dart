import 'package:flutter/material.dart';
import 'package:boardroom_booking/services/api_service.dart';

class NetworkStatusWidget extends StatefulWidget {
  const NetworkStatusWidget({super.key});

  @override
  State<NetworkStatusWidget> createState() => _NetworkStatusWidgetState();
}

class _NetworkStatusWidgetState extends State<NetworkStatusWidget> {
  bool? _isConnected;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final isConnected = await ApiService.testConnectivity();
      setState(() {
        _isConnected = isConnected;
        _isChecking = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text(
              'Checking connection...',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (_isConnected == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _checkConnection,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _isConnected! ? Colors.green.shade100 : Colors.red.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isConnected! ? Icons.wifi : Icons.wifi_off,
              size: 12,
              color:
                  _isConnected! ? Colors.green.shade700 : Colors.red.shade700,
            ),
            const SizedBox(width: 8),
            Text(
              _isConnected! ? 'Connected' : 'Disconnected',
              style: TextStyle(
                fontSize: 12,
                color:
                    _isConnected! ? Colors.green.shade700 : Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
