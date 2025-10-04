import 'package:flutter/foundation.dart';

import '../models/student.dart';
import '../models/attendance.dart';

/// Ephemeral, in-memory store that lasts while the app is running.
/// Data disappears when the app is restarted or the tab/process closes.
class RuntimeStore {
  static final List<Student> _students = <Student>[];
  static final List<AttendanceRecord> _attendance = <AttendanceRecord>[];
  static final List<AttendanceRecord> _history = <AttendanceRecord>[];
  static final ValueNotifier<int> version = ValueNotifier<int>(0);

  static void _bump() {
    version.value = version.value + 1;
  }

  // Students
  static List<Student> getStudents() => List.unmodifiable(_students);

  static void addStudent(Student s) {
    // Replace if same id already present
    _students.removeWhere((e) => e.id == s.id);
    _students.add(s);
    _bump();
  }

  // Attendance
  static List<AttendanceRecord> getAttendance() => List.unmodifiable(_attendance);
  static List<AttendanceRecord> getHistory() => List.unmodifiable(_history);

  static int _nextAttendanceId() {
    if (_attendance.isEmpty) return 100000; // temp ids
    return _attendance.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
  }

  static AttendanceRecord addAttendanceForStudent(int studentId) {
    final rec = AttendanceRecord(
      id: _nextAttendanceId(),
      studentId: studentId,
      timestamp: DateTime.now(),
    );
    _attendance.add(rec);
    _history.add(rec);
    _bump();
    return rec;
  }

  static void addAttendance(AttendanceRecord r) {
    _attendance.add(r);
    _history.add(r);
    _bump();
  }

  static void clear() {
    _students.clear();
    _attendance.clear();
    _history.clear();
    _bump();
  }
}
