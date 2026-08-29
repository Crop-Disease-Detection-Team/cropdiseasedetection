class Medicine {
  final int? id;
  final String medicineName;
  final String? activeIngredient;
  final String? type;
  final String? applicationMethod;
  final String? dosagePerLiter;
  final int? waitingPeriodDays;
  final String? safetyPrecautions;
  final double? priceEstimate;
  final String? manufacturer;
  final bool isOrganic;

  Medicine({
    this.id,
    required this.medicineName,
    this.activeIngredient,
    this.type,
    this.applicationMethod,
    this.dosagePerLiter,
    this.waitingPeriodDays,
    this.safetyPrecautions,
    this.priceEstimate,
    this.manufacturer,
    this.isOrganic = false,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        // NOTE: /api/predict's medicine list has no 'id' field (only the
        // /api/user/diseases/<id> detail endpoint includes it) — keep nullable.
        id: json['id'] as int?,
        medicineName: json['medicine_name'] ?? '',
        activeIngredient: json['active_ingredient'],
        type: json['type'],
        applicationMethod: json['application_method'],
        dosagePerLiter: json['dosage_per_liter'],
        waitingPeriodDays: json['waiting_period_days'],
        safetyPrecautions: json['safety_precautions'],
        priceEstimate: (json['price_estimate'] as num?)?.toDouble(),
        manufacturer: json['manufacturer'],
        isOrganic: json['is_organic'] ?? false,
      );
}

class Disease {
  final int? id;
  final String diseaseName;
  final String? diseaseCode;
  final String? cropType;
  final String? scientificName;
  final String? description;
  final String? symptoms;
  final String? causes;
  final String? organicTreatment;
  final String? chemicalTreatment;
  final String? preventionTips;
  final String? severityLevel;
  final String? typicalDuration;
  final String? affectedCropParts;
  final String? youtubeTutorialUrl;
  final String? referenceImageUrl;
  final String? sampleImageUrl;
  final String? cultivationRegions;
  final List<Medicine> medicines;
  final double? confidence; // present only on prediction results

  Disease({
    this.id,
    required this.diseaseName,
    this.diseaseCode,
    this.cropType,
    this.scientificName,
    this.description,
    this.symptoms,
    this.causes,
    this.organicTreatment,
    this.chemicalTreatment,
    this.preventionTips,
    this.severityLevel,
    this.typicalDuration,
    this.affectedCropParts,
    this.youtubeTutorialUrl,
    this.referenceImageUrl,
    this.sampleImageUrl,
    this.cultivationRegions,
    this.medicines = const [],
    this.confidence,
  });

  factory Disease.fromJson(Map<String, dynamic> json) => Disease(
        id: json['disease_id'] ?? json['id'],
        diseaseName: json['disease_name'] ?? 'Unknown',
        diseaseCode: json['disease_code'],
        cropType: json['crop_type'],
        scientificName: json['scientific_name'],
        description: json['description'],
        symptoms: json['symptoms'],
        causes: json['causes'],
        organicTreatment: json['organic_treatment'],
        chemicalTreatment: json['chemical_treatment'],
        preventionTips: json['prevention_tips'],
        severityLevel: json['severity_level'],
        typicalDuration: json['typical_duration'],
        affectedCropParts: json['affected_crop_parts'],
        youtubeTutorialUrl: json['youtube_tutorial_url'],
        referenceImageUrl: json['reference_image_url'],
        sampleImageUrl: json['sample_image_url'],
        cultivationRegions: json['cultivation_regions'],
        medicines: (json['medicines'] as List<dynamic>? ?? [])
            .map((m) => Medicine.fromJson(m as Map<String, dynamic>))
            .toList(),
        confidence: (json['confidence'] as num?)?.toDouble(),
      );
}