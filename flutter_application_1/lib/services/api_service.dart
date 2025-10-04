import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/student.dart';
import '../models/attendance.dart';
import 'runtime_store.dart';

class ApiService {
  ApiService._();
  static final http.Client _client = http.Client();

  static Uri _studentsUri([String pathSuffix = '']) =>
      Uri.parse('${AppConfig.baseUrl}${AppConfig.studentsPath}$pathSuffix');

  static Uri _attendanceUri([String pathSuffix = '']) =>
      Uri.parse('${AppConfig.baseUrl}${AppConfig.attendancePath}$pathSuffix');

  // STUDENTS
  static Future<List<Student>> fetchStudents() async {
    List<Student> remote = const <Student>[];
    try {
      final res = await _client.get(_studentsUri());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        if (body is List) {
          remote = body.map((e) => Student.fromJson(e as Map<String, dynamic>)).toList();
        }
      }
    } catch (_) {}

    // Merge with runtime additions
    final map = <int, Student>{ for (final s in remote) s.id: s };
    for (final s in RuntimeStore.getStudents()) {
      map[s.id] = s;
    }
    return map.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  static Future<Student?> addStudent(Student student) async {
    // Save to runtime immediately so UI reflects without persistence.
    RuntimeStore.addStudent(student);

    try {
      final res = await _client.post(
        _studentsUri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(student.toJson()),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        // My JSON Server fakes the write; parse but keep runtime stored version.
        final body = jsonDecode(res.body);
        return Student.fromJson(body as Map<String, dynamic>);
      }
    } catch (_) {}
    return student;
  }

  // ATTENDANCE
  static Future<List<AttendanceRecord>> fetchAttendance() async {
    List<AttendanceRecord> remote = const <AttendanceRecord>[];
    try {
      final res = await _client.get(_attendanceUri());
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        if (body is List) {
          remote = body
              .map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}

    final list = [
      ...remote,
      ...RuntimeStore.getAttendance(),
    ];
    // De-duplicate by id (runtime ids may be large temp values)
    final seen = <int>{};
    final merged = <AttendanceRecord>[];
    for (final r in list) {
      if (seen.add(r.id)) merged.add(r);
    }
    merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return merged;
  }

  static Future<AttendanceRecord?> addAttendance(int studentId) async {
    // Add locally first for instant dashboard reflection
    final local = RuntimeStore.addAttendanceForStudent(studentId);

    try {
      final payload = {
        'id': 0,
        'studentId': studentId,
        'timestamp': local.timestamp.toIso8601String(),
      };
      final res = await _client.post(
        _attendanceUri(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = jsonDecode(res.body);
        return AttendanceRecord.fromJson(body as Map<String, dynamic>);
      }
    } catch (_) {}
    return local;
  }
}
