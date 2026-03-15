class ImportCourse {
  ImportCourse({
    required this.name,
    this.classroom,
    this.classNumber,
    this.teacher,
    required this.weeks,
    required this.weekTime,
    required this.startTime,
    required this.timeCount,
  });

  final String name;
  final String? classroom;
  final String? classNumber;
  final String? teacher;
  final List<int> weeks;
  final int weekTime;
  final int startTime;
  final int timeCount;
}
