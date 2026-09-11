class JobModel {
  final String id;
  final String company;
  final String position;
  final DateTime appliedDate;
  final String status; // 'To Apply', 'Applied', 'Assessment', 'Interview', 'Waiting', 'Selected', 'Rejected'
  final DateTime? testDate;
  final DateTime? interviewDate;
  final String? result;
  final String? package; // e.g. '₹8.5 LPA'
  final String? location; // e.g. 'Bangalore / Remote'
  final String? jobLink;
  final String? notes;

  JobModel({
    required this.id,
    required this.company,
    required this.position,
    required this.appliedDate,
    required this.status,
    this.testDate,
    this.interviewDate,
    this.result,
    this.package,
    this.location,
    this.jobLink,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company': company,
      'position': position,
      'appliedDate': appliedDate.toIso8601String(),
      'status': status,
      'testDate': testDate?.toIso8601String() ?? '',
      'interviewDate': interviewDate?.toIso8601String() ?? '',
      'result': result ?? '',
      'package': package ?? '',
      'location': location ?? '',
      'jobLink': jobLink ?? '',
      'notes': notes ?? '',
    };
  }

  factory JobModel.fromMap(Map<String, dynamic> map) {
    return JobModel(
      id: map['id'] as String,
      company: map['company'] as String,
      position: map['position'] as String,
      appliedDate: DateTime.parse(map['appliedDate'] as String),
      status: map['status'] as String,
      testDate: (map['testDate'] as String?)?.isNotEmpty == true ? DateTime.parse(map['testDate'] as String) : null,
      interviewDate: (map['interviewDate'] as String?)?.isNotEmpty == true ? DateTime.parse(map['interviewDate'] as String) : null,
      result: (map['result'] as String?)?.isEmpty ?? true ? null : map['result'] as String,
      package: (map['package'] as String?)?.isEmpty ?? true ? null : map['package'] as String,
      location: (map['location'] as String?)?.isEmpty ?? true ? null : map['location'] as String,
      jobLink: (map['jobLink'] as String?)?.isEmpty ?? true ? null : map['jobLink'] as String,
      notes: (map['notes'] as String?)?.isEmpty ?? true ? null : map['notes'] as String,
    );
  }
}
