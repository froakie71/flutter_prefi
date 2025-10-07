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
  bool _studentsLoaded = false;
  final Set<int> _studentIds = <int>{};
  final MobileScannerController _controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    final list = await ApiService.fetchStudents();
    if (!mounted) return;
    setState(() {
      _studentIds
        ..clear()
        ..addAll(list.map((e) => e.id));
      _studentsLoaded = true;
    });
  }

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

    // Ensure student exists before recording attendance
    if (!_studentsLoaded) {
      await _loadStudents();
    }
    if (!_studentIds.contains(studentId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unknown student ID: $studentId')),
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
      appBar: AppBar(
        title: const Text('QR Scanner'),
        actions: [
          IconButton(
            tooltip: 'Flash',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            tooltip: 'Switch camera (front/back)',
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              fit: BoxFit.cover,
              onDetect: _onDetect,
            ),
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
