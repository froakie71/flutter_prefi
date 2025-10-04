import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/student.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = false;
  List<Student> _students = [];
  List<AttendanceRecord> _attendance = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      ApiService.fetchStudents(),
      ApiService.fetchAttendance(),
    ]);
    if (!mounted) return;
    setState(() {
      _students = results[0] as List<Student>;
      _attendance = (results[1] as List<AttendanceRecord>)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _loading = false;
    });
  }

  int get _todayCount {
    final now = DateTime.now();
    return _attendance.where((r) => r.timestamp.year == now.year && r.timestamp.month == now.month && r.timestamp.day == now.day).length;
  }

  String _studentName(int id) {
    final s = _students.cast<Student?>().firstWhere((e) => e?.id == id, orElse: () => null);
    return s?.fullName ?? 'ID $id';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _MetricCard(title: 'Students', value: _students.length.toString(), icon: Icons.people_alt),
                      _MetricCard(title: 'Today\'s Check-ins', value: _todayCount.toString(), icon: Icons.event_available),
                      _MetricCard(title: 'Total Attendance', value: _attendance.length.toString(), icon: Icons.task_alt),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Recent Check-ins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      child: ListView.separated(
                        itemCount: _attendance.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final r = _attendance[i];
                          final ts = DateFormat('yyyy-MM-dd HH:mm').format(r.timestamp.toLocal());
                          return ListTile(
                            leading: const Icon(Icons.qr_code_2),
                            title: Text(_studentName(r.studentId)),
                            subtitle: Text('ID ${r.studentId} • $ts'),
                          );
                        },
                      ),
                    ),
                  )
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

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const _MetricCard({required this.title, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 110,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, size: 40),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                  Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
