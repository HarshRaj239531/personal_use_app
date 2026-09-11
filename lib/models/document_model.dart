class DocumentModel {
  final String id;
  final String title;
  final String type; // 'Education', 'Identity', 'Employment', 'Financial', 'Other'
  final String year; // e.g. '2026'
  final String status; // 'Available', 'Verified', 'Expiring Soon'
  final String? identifierNo; // e.g. Roll No / Reg No
  final DateTime? expiryDate;
  final String? notes;
  final bool hasFile;

  DocumentModel({
    required this.id,
    required this.title,
    required this.type,
    required this.year,
    this.status = 'Available',
    this.identifierNo,
    this.expiryDate,
    this.notes,
    this.hasFile = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'year': year,
      'status': status,
      'identifierNo': identifierNo ?? '',
      'expiryDate': expiryDate?.toIso8601String() ?? '',
      'notes': notes ?? '',
      'hasFile': hasFile ? 1 : 0,
    };
  }

  factory DocumentModel.fromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      year: map['year'] as String,
      status: map['status'] as String? ?? 'Available',
      identifierNo: (map['identifierNo'] as String?)?.isEmpty ?? true ? null : map['identifierNo'] as String,
      expiryDate: (map['expiryDate'] as String?)?.isNotEmpty == true ? DateTime.parse(map['expiryDate'] as String) : null,
      notes: (map['notes'] as String?)?.isEmpty ?? true ? null : map['notes'] as String,
      hasFile: (map['hasFile'] as int? ?? 1) == 1,
    );
  }
}
