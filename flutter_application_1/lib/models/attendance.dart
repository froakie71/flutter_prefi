class AttendanceRecord {
  final int id;
  final int studentId;
  final DateTime timestamp;

  AttendanceRecord({required this.id, required this.studentId, required this.timestamp});

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      studentId: json['studentId'] is int
          ? json['studentId'] as int
          : int.tryParse('${json['studentId']}') ?? 0,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'studentId': studentId,
        'timestamp': timestamp.toIso8601String(),
      };
}
