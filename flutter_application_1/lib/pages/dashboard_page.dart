import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:intl/intl.dart';

import '../models/student.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';
import '../services/runtime_store.dart';
import '../utils/file_saver_stub.dart'
    if (dart.library.io) '../utils/file_saver_io.dart'
    if (dart.library.html) '../utils/file_saver_web.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
// Using default embedded fonts; for Unicode, we can embed a TTF later if needed.

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
            : DefaultTabController(
                length: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Export buttons centered
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: _exportCsv,
                          icon: const Icon(Icons.table_view),
                          label: const Text('Export CSV'),
                        ),
                        FilledButton.icon(
                          onPressed: _exportPdf,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export PDF'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Centered tab bar with constrained width so it sits perfectly in the middle
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: TabBar(
                          isScrollable: true,
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          // 4px left + 4px right = 8px gap between tabs (matches export buttons spacing)
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                          tabs: const [
                            Tab(text: 'Overview'),
                            Tab(text: 'Recent'),
                          ],
                        ),
                      ),
                    ),
                    // Tab contents with bounded height
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Overview tab
                          SingleChildScrollView(
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16,
                              runSpacing: 16,
                              children: [
                                _MetricCard(title: 'Students', value: _students.length.toString(), icon: Icons.people_alt),
                                _MetricCard(title: "Today's Check-ins", value: _todayCount.toString(), icon: Icons.event_available),
                                _MetricCard(title: 'Total Attendance', value: _attendance.length.toString(), icon: Icons.task_alt),
                              ],
                            ),
                          ),
                          // Recent tab
                          ListView.separated(
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
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _reload,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }

  Future<void> _exportCsv() async {
    final sb = StringBuffer();
    sb.writeln('Students');
    sb.writeln('id,firstName,lastName,section,gradeLevel');
    for (final s in _students) {
      sb.writeln('${s.id},"${s.firstName}","${s.lastName}","${s.section ?? ''}","${s.gradeLevel ?? ''}"');
    }
    sb.writeln();
    sb.writeln('Attendance');
    sb.writeln('id,studentId,studentName,timestamp');
    for (final r in _attendance) {
      final name = _studentName(r.studentId);
      sb.writeln('${r.id},${r.studentId},"$name","${r.timestamp.toIso8601String()}"');
    }
    final ok = await FileSaver.saveText('attendance_report.csv', sb.toString(), 'text/csv');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'CSV saved (download on web, Documents on mobile).' : 'Saving failed on this platform.')),
    );
  }

  Future<void> _exportPdf() async {
    final doc = pw.Document();
    final df = DateFormat('yyyy-MM-dd HH:mm');
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) {
          return [
            pw.Header(level: 0, child: pw.Text('Attendance Report')), 
            pw.Paragraph(text: 'Generated: ${DateTime.now().toLocal()}'),
            pw.SizedBox(height: 12),
            pw.Text('Summary', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Bullet(text: 'Students: ${_students.length}'),
            pw.Bullet(text: 'Today\'s Check-ins: ${_todayCount}'),
            pw.Bullet(text: 'Total Attendance: ${_attendance.length}'),
            pw.SizedBox(height: 12),
            pw.Text('Recent Check-ins', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Table.fromTextArray(
              headers: const ['ID', 'Student', 'Timestamp'],
              data: _attendance.take(50).map((r) => [
                r.studentId.toString(),
                _studentName(r.studentId),
                df.format(r.timestamp.toLocal()),
              ]).toList(),
              cellStyle: const pw.TextStyle(fontSize: 10),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ];
        },
      ),
    );
    final bytes = await doc.save();
    if (kIsWeb) {
      final ok = await FileSaver.saveBytes('attendance_report.pdf', bytes, 'application/pdf');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ok ? 'PDF downloaded.' : 'Saving failed on this platform.')),
      );
    } else {
      // On mobile/desktop, try system share sheet first; if the plugin
      // isn't registered on this build, fall back to direct save.
      try {
        await Printing.sharePdf(bytes: bytes, filename: 'attendance_report.pdf');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF ready. Choose an app to save/share.')),
        );
      } on MissingPluginException {
        final ok = await FileSaver.saveBytes('attendance_report.pdf', bytes, 'application/pdf');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'PDF saved to app storage.' : 'Saving failed on this platform.')),
        );
      } catch (e) {
        final ok = await FileSaver.saveBytes('attendance_report.pdf', bytes, 'application/pdf');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ok ? 'PDF saved to app storage.' : 'Saving failed: $e')),
        );
      }
    }
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
