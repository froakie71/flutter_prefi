class AppConfig {
  // TODO: Replace with your GitHub username and repo that contains db.json
  // Example: https://my-json-server.typicode.com/<user>/<repo>
  static const String githubUser = 'froakie71';
  static const String githubRepo = 'flutter_prefi';

  static String get baseUrl =>
      'https://my-json-server.typicode.com/$githubUser/$githubRepo';

  // Endpoints expected in your db.json
  // {
  //   "students": [ {"id": 1, "name": "Alice"} ],
  //   "attendance": [ {"id": 1, "studentId": 1, "timestamp": "2025-10-04T00:00:00.000Z"} ]
  // }
  static const String studentsPath = '/students';
  static const String attendancePath = '/attendance';
  static const String historyPath = '/history';
}
