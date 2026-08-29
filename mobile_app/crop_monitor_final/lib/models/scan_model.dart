class ScanRecord {
  final int id;
  final String diseaseName;
  final double confidence;
  final String? severity;
  final String? recommendation;
  final String? scannedAt;
  final String? imageUrl;

  ScanRecord({
    required this.id,
    required this.diseaseName,
    required this.confidence,
    this.severity,
    this.recommendation,
    this.scannedAt,
    this.imageUrl,
  });

  /// Accepts confidence/id as either a number or a numeric string.
  /// The backend can end up sending SQL Decimal fields as JSON strings
  /// (a Flask/SQLAlchemy quirk), so we don't want a strict `as num` cast
  /// to crash the whole history screen if that ever slips through again.
  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: _toInt(json['id']),
        diseaseName: json['disease_name'] ?? 'Unknown',
        confidence: _toDouble(json['confidence']),
        severity: json['severity'],
        recommendation: json['recommendation'],
        scannedAt: json['scanned_at'],
        // predict_bp uses 'image_url', disease_bp uses 'image_path' — accept either.
        imageUrl: json['image_url'] ?? json['image_path'],
      );

  /// Backend confidence values are inconsistently scaled (0–1 vs 0–100)
  /// depending on which code path wrote them — the web app normalizes
  /// this client-side too, so we do the same rather than trusting the
  /// raw number as already being a percentage.
  double get displayConfidence => confidence <= 1 ? confidence * 100 : confidence;
}
