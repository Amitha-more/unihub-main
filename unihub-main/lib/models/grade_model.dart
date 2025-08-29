class Subject {
  final String code;
  final String name;
  final int credits;
  final double isa1;
  final double isa2;
  final double assignment;
  final double ese;
  double? gradePoint;

  Subject({
    required this.code,
    required this.name,
    required this.credits,
    required this.isa1,
    required this.isa2,
    required this.assignment,
    required this.ese,
    this.gradePoint,
  });

  // Calculate total internal marks (ISA1 + ISA2 + Assignment)
  double get internalMarks => isa1 + isa2 + assignment;

  // Calculate total marks (Internal + ESE)
  double get totalMarks => internalMarks + ese;

  // Calculate grade point based on total marks
  double calculateGradePoint() {
    final total = totalMarks;
    if (total >= 90) return 10.0;      // S Grade
    if (total >= 80) return 9.0;       // A Grade
    if (total >= 70) return 8.0;       // B Grade
    if (total >= 60) return 7.0;       // C Grade
    if (total >= 50) return 6.0;       // D Grade
    if (total >= 45) return 5.0;       // E Grade
    return 0.0;                        // F Grade
  }

  // Get grade letter based on grade point
  String get gradeLetter {
    final gp = gradePoint ?? calculateGradePoint();
    if (gp >= 10.0) return 'S';
    if (gp >= 9.0) return 'A';
    if (gp >= 8.0) return 'B';
    if (gp >= 7.0) return 'C';
    if (gp >= 6.0) return 'D';
    if (gp >= 5.0) return 'E';
    return 'F';
  }

  Subject copyWith({
    String? code,
    String? name,
    int? credits,
    double? isa1,
    double? isa2,
    double? assignment,
    double? ese,
    double? gradePoint,
  }) {
    return Subject(
      code: code ?? this.code,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      isa1: isa1 ?? this.isa1,
      isa2: isa2 ?? this.isa2,
      assignment: assignment ?? this.assignment,
      ese: ese ?? this.ese,
      gradePoint: gradePoint ?? this.gradePoint,
    );
  }
}

class Semester {
  final int number;
  final List<Subject> subjects;
  double? sgpa;

  Semester({
    required this.number,
    required this.subjects,
    this.sgpa,
  });

  // Calculate SGPA
  double calculateSGPA() {
    if (subjects.isEmpty) return 0.0;

    double totalCredits = 0;
    double totalGradePoints = 0;

    for (final subject in subjects) {
      final gradePoint = subject.gradePoint ?? subject.calculateGradePoint();
      totalCredits += subject.credits;
      totalGradePoints += (gradePoint * subject.credits);
    }

    return totalGradePoints / totalCredits;
  }

  Semester copyWith({
    int? number,
    List<Subject>? subjects,
    double? sgpa,
  }) {
    return Semester(
      number: number ?? this.number,
      subjects: subjects ?? this.subjects,
      sgpa: sgpa ?? this.sgpa,
    );
  }
}

class CGPA {
  final List<Semester> semesters;
  double? cgpa;

  CGPA({
    required this.semesters,
    this.cgpa,
  });

  // Calculate CGPA
  double calculateCGPA() {
    if (semesters.isEmpty) return 0.0;

    double totalCredits = 0;
    double totalGradePoints = 0;

    for (final semester in semesters) {
      for (final subject in semester.subjects) {
        final gradePoint = subject.gradePoint ?? subject.calculateGradePoint();
        totalCredits += subject.credits;
        totalGradePoints += (gradePoint * subject.credits);
      }
    }

    return totalGradePoints / totalCredits;
  }

  CGPA copyWith({
    List<Semester>? semesters,
    double? cgpa,
  }) {
    return CGPA(
      semesters: semesters ?? this.semesters,
      cgpa: cgpa ?? this.cgpa,
    );
  }
} 