import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/student.dart';
import '../services/api_service.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({super.key});

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _sectionCtrl = TextEditingController();
  final _gradeLevelCtrl = TextEditingController();

  List<Student> _students = [];
  // Keep locally added students so they show up even if My JSON Server doesn't persist
  final List<Student> _localAdditions = [];

  Student? _selectedForQr;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final remote = await ApiService.fetchStudents();
    if (!mounted) return;
    setState(() {
      _students = [...remote, ..._localAdditions];
      _loading = false;
    });
  }

  int _nextId() {
    final all = [..._students, ..._localAdditions];
    if (all.isEmpty) return 1;
    return (all.map((s) => s.id).reduce((a, b) => a > b ? a : b)) + 1;
  }

  Future<void> _addStudent() async {
    final first = _firstCtrl.text.trim();
    final last = _lastCtrl.text.trim();
    if (first.isEmpty || last.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('First name and Last name are required.')),
      );
      return;
    }
    final section = _sectionCtrl.text.trim();
    final gradeLevel = _gradeLevelCtrl.text.trim();

    final s = Student(
      id: _nextId(),
      firstName: first,
      lastName: last,
      section: section.isEmpty ? null : section,
      gradeLevel: gradeLevel.isEmpty ? null : gradeLevel,
    );
    final created = await ApiService.addStudent(s);

    // Regardless of persistence, reflect immediately
    setState(() {
      _localAdditions.add(created ?? s);
      _students = [..._students, created ?? s];
      _firstCtrl.clear();
      _lastCtrl.clear();
      _sectionCtrl.clear();
      _gradeLevelCtrl.clear();
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student added (My JSON Server may not persist).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _firstCtrl,
                    decoration: const InputDecoration(labelText: 'First name', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lastCtrl,
                    decoration: const InputDecoration(labelText: 'Last name', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _sectionCtrl,
                    decoration: const InputDecoration(labelText: 'Section (optional)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _gradeLevelCtrl,
                    decoration: const InputDecoration(labelText: 'Grade level (optional)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(onPressed: _addStudent, icon: const Icon(Icons.add), label: const Text('Add')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.tonal(onPressed: _load, child: const Text('Refresh')),
                const SizedBox(width: 12),
                if (_selectedForQr != null) Text('  QR for ID: ${_selectedForQr!.id}')
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Card(
                            child: ListView.separated(
                              itemCount: _students.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final s = _students[i];
                                return ListTile(
                                  leading: CircleAvatar(child: Text(s.id.toString())),
                                  title: Text(s.fullName),
                                  subtitle: Text('Section: ${s.section ?? '-'} • Grade: ${s.gradeLevel ?? '-'}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.qr_code_2),
                                    onPressed: () => setState(() => _selectedForQr = s),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Card(
                            child: Center(
                              child: _selectedForQr == null
                                  ? const Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Text('Select a student to generate QR'),
                                    )
                                  : Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(height: 12),
                                        Text(_selectedForQr!.fullName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 12),
                                        // Encode as sid:<id> so scanner can parse reliably
                                        QrImageView(
                                          data: 'sid:${_selectedForQr!.id}',
                                          version: QrVersions.auto,
                                          size: 220,
                                        ),
                                        const SizedBox(height: 12),
                                        Text('QR encodes: sid:${_selectedForQr!.id}')
                                      ],
                                    ),
                            ),
                          ),
                        )
                      ],
                    ),
            )
          ],
        ),
      ),
    );
  }
}
