import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/student.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';
import '../services/runtime_store.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  bool _loading = false;
  List<Student> _students = [];
  List<AttendanceRecord> _history = [];

  @override
  void initState() {
    super.initState();
    _reload();
    RuntimeStore.version.addListener(_reload);
  }

  @override
  void dispose() {
    RuntimeStore.version.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.fetchStudents(),
      ApiService.fetchHistory(),
    ]);
    if (!mounted) return;
    setState(() {
      _students = results[0] as List<Student>;
      _history = (results[1] as List<AttendanceRecord>)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _loading = false;
    });
  }

  String _studentName(int id) {
    final s = _students.cast<Student?>().firstWhere((e) => e?.id == id, orElse: () => null);
    return s?.fullName ?? 'ID $id';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Card(
                      child: ListView.separated(
                        itemCount: _history.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final r = _history[i];
                          final ts = DateFormat('yyyy-MM-dd HH:mm').format(r.timestamp.toLocal());
                          return ListTile(
                            leading: const Icon(Icons.history),
                            title: Text(_studentName(r.studentId)),
                            subtitle: Text('ID ${r.studentId} • $ts'),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _reload,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }
}
