class Student {
  final int id;
  final String firstName;
  final String lastName;
  final String? section;
  final String? gradeLevel;

  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.section,
    this.gradeLevel,
  });

  String get fullName =>
      '${firstName.trim()} ${lastName.trim()}'.trim().replaceAll(RegExp(r'\s+'), ' ');

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      section: json['section']?.toString(),
      gradeLevel: json['gradeLevel']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        if (section != null) 'section': section,
        if (gradeLevel != null) 'gradeLevel': gradeLevel,
      };
}
