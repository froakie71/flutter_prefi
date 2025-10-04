import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../services/api_service.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool _processing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue ?? '';

    int? studentId;
    // Accept either a plain integer or a string like "sid:123"
    final sidMatch = RegExp(r'^sid:(\d+)\s*$').firstMatch(raw);
    if (sidMatch != null) {
      studentId = int.tryParse(sidMatch.group(1)!);
    } else {
      studentId = int.tryParse(raw.trim());
    }

    if (studentId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR. Expected student ID.')),
      );
      return;
    }

    setState(() => _processing = true);
    try {
      final rec = await ApiService.addAttendance(studentId);
      if (!mounted) return;
      if (rec != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Check-in recorded for student #${rec.studentId}')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record attendance')),
        );
      }
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Scanner')),
      body: Stack(
        children: [
          MobileScanner(
            fit: BoxFit.contain,
            onDetect: _onDetect,
          ),
          if (_processing)
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
