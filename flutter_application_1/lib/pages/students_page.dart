import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/student.dart';
import '../services/api_service.dart';
import '../widgets/animations.dart';

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
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _openAllStudentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('All Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _students.isEmpty
                      ? const Center(child: Text('No students found. Tap Refresh on the page.'))
                      : ListView.separated(
                          itemCount: _students.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final s = _students[i];
                            final delay = Duration(milliseconds: (i % 24) * 40);
                            return FadeSlide(
                              delay: delay,
                              child: ListTile(
                                leading: CircleAvatar(child: Text(s.id.toString())),
                                title: Text(s.fullName),
                                subtitle: Text('Section: ${s.section ?? '-'} • Grade: ${s.gradeLevel ?? '-'}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.qr_code_2),
                                  onPressed: () => _showQrBottomSheet(s),
                                ),
                                onTap: () => _showQrBottomSheet(s),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await ApiService.fetchStudents();
    if (!mounted) return;
    setState(() {
      _students = list;
      _loading = false;
    });
  }

  int _nextId() {
    final all = [..._students];
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
    await ApiService.addStudent(s);
    await _load();
    _firstCtrl.clear();
    _lastCtrl.clear();
    _sectionCtrl.clear();
    _gradeLevelCtrl.clear();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Student added (My JSON Server may not persist).')),
    );
  }

  void _showQrBottomSheet(Student s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: FadeSlide(
              child: QrImageView(
                data: 'sid:${s.id}',
                version: QrVersions.auto,
                size: 260,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 640;
    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Add Student', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: _openAllStudentsSheet,
                  icon: const Icon(Icons.list),
                  label: const Text('All Students'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isNarrow)
              Column(
                children: [
                  TextField(
                    controller: _firstCtrl,
                    decoration: const InputDecoration(labelText: 'First name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lastCtrl,
                    decoration: const InputDecoration(labelText: 'Last name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sectionCtrl,
                    decoration: const InputDecoration(labelText: 'Section (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _gradeLevelCtrl,
                    decoration: const InputDecoration(labelText: 'Grade level (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(onPressed: _addStudent, icon: const Icon(Icons.add), label: const Text('Add')),
                  ),
                ],
              )
            else
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
            const SizedBox(height: 8),
            if (_loading) const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: LinearProgressIndicator(minHeight: 3),
            ),
            // List is now in the "All Students" sheet.
          ],
        ),
      ),
    );
  }
}
