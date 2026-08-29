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

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: json['id'],
        diseaseName: json['disease_name'] ?? 'Unknown',
        confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
        severity: json['severity'],
        recommendation: json['recommendation'],
        scannedAt: json['scanned_at'],
        // predict_bp uses 'image_url', disease_bp uses 'image_path' — accept either.
        imageUrl: json['image_url'] ?? json['image_path'],
      );
}
