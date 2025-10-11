import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import '../services/runtime_store.dart';
import '../models/student.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool _processing = false;
  final MobileScannerController _controller = MobileScannerController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Removed preloading of students; we fetch a specific student by ID on scan.

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final raw = barcodes.first.rawValue ?? '';

    int? studentId;
    // Accept formats:
    // 1) "sid:123"
    // 2) "123"
    // 3) Full URL: https://my-json-server.typicode.com/<user>/<repo>/students/123
    final sidMatch = RegExp(r'^sid:(\d+)\s*$').firstMatch(raw);
    if (sidMatch != null) {
      studentId = int.tryParse(sidMatch.group(1)!);
    } else {
      // Try plain integer
      studentId = int.tryParse(raw.trim());
      if (studentId == null) {
        // Try URL parse
        final uri = Uri.tryParse(raw.trim());
        if (uri != null && uri.pathSegments.isNotEmpty) {
          // Look for .../students/<id>
          final segments = uri.pathSegments;
          final idx = segments.lastIndexOf('students');
          if (idx != -1 && idx + 1 < segments.length) {
            studentId = int.tryParse(segments[idx + 1]);
          } else {
            // Fallback: last segment as ID
            studentId = int.tryParse(segments.last);
          }
        }
      }
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
      // Fetch the specific student via JSON server; if missing, fall back to local runtime store
      Student? student = await ApiService.fetchStudentById(studentId);
      student ??= () {
        for (final s in RuntimeStore.getStudents()) {
          if (s.id == studentId) return s;
        }
        return null;
      }();
      if (student == null) {
        // As a last resort, fetch the merged list (remote + runtime) and try again
        final merged = await ApiService.fetchStudents();
        for (final s in merged) {
          if (s.id == studentId) {
            student = s;
            break;
          }
        }
      }

      final rec = await ApiService.addAttendance(studentId);
      if (!mounted) return;
      if (rec != null) {
        final ts = DateFormat('yyyy-MM-dd HH:mm').format(rec.timestamp.toLocal());
        final parts = <String>[];
        if (student != null) {
          parts.add(student.fullName);
          if ((student.section ?? '').isNotEmpty) parts.add('Section: ${student.section}');
          if ((student.gradeLevel ?? '').isNotEmpty) parts.add('Grade: ${student.gradeLevel}');
        } else {
          parts.add('ID $studentId');
        }
        final details = parts.join(' • ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Checked in $details at $ts')),
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
