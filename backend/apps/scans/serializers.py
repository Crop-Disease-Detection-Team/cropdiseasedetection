from rest_framework import serializers

from .models import Crop, Disease, Medicine, DiseaseMedicineMapping, ScanHistory


class CropSerializer(serializers.ModelSerializer):
    disease_count = serializers.IntegerField(source='diseases.count', read_only=True)

    class Meta:
        model = Crop
        fields = ['id', 'name', 'scientific_name', 'disease_count']


class MedicineSerializer(serializers.ModelSerializer):
    class Meta:
        model = Medicine
        fields = [
            'id', 'name', 'type', 'active_ingredients', 'manufacturer',
            'dosage_guidance', 'application_method', 'safety_precautions',
            'description', 'created_at',
        ]


class DiseaseMedicineMappingSerializer(serializers.ModelSerializer):
    medicine = MedicineSerializer(read_only=True)

    class Meta:
        model = DiseaseMedicineMapping
        fields = ['id', 'medicine']


class DiseaseSerializer(serializers.ModelSerializer):
    crop_name = serializers.CharField(source='crop.name', read_only=True)
    crop_scientific_name = serializers.CharField(source='crop.scientific_name', read_only=True)
    medicines = serializers.SerializerMethodField()

    class Meta:
        model = Disease
        fields = [
            'id', 'crop', 'crop_name', 'crop_scientific_name',
            'name', 'scientific_name', 'family', 'description',
            'symptoms', 'causes',
            'organic_treatments', 'chemical_treatments', 'prevention_tips',
            'affected_parts', 'duration', 'weather',
            'severity', 'sample_image',
            'regional_recommendation', 'nearby_agricultural_office',
            'medicines',
        ]

    def get_medicines(self, obj):
        mappings = obj.medicine_mappings.select_related('medicine').all()
        return DiseaseMedicineMappingSerializer(mappings, many=True).data


class DiseaseListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for list views (no medicines, no heavy fields)."""
    crop_name = serializers.CharField(source='crop.name', read_only=True)

    class Meta:
        model = Disease
        fields = [
            'id', 'crop', 'crop_name', 'name', 'scientific_name',
            'severity', 'sample_image', 'description',
        ]


class ScanHistorySerializer(serializers.ModelSerializer):
    disease_name = serializers.CharField(source='disease.name', read_only=True)
    crop_type = serializers.CharField(source='disease.crop.name', read_only=True)
    recommendation = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()
    scanned_at = serializers.DateTimeField(source='created_at', read_only=True)

    class Meta:
        model = ScanHistory
        fields = [
            'id',
            'image',
            'image_url',
            'disease_name',
            'crop_type',
            'confidence',
            'healthy_probability',
            'disease_probability',
            'recommendation',
            'raw_response',
            'device_information',
            'location_data',
            'created_at',
            'scanned_at',
        ]
        read_only_fields = fields

    def get_image_url(self, obj):
        request = self.context.get('request')
        if not obj.image:
            return ''
        url = obj.image.url
        return request.build_absolute_uri(url) if request else url

    def get_recommendation(self, obj):
        if obj.raw_response.get('recommendation'):
            return obj.raw_response['recommendation']
        if obj.raw_response.get('treatment'):
            return obj.raw_response['treatment']
        if obj.disease:
            treatments = obj.disease.organic_treatments or obj.disease.chemical_treatments or obj.disease.prevention_tips
            if isinstance(treatments, list):
                return '\n'.join(str(item) for item in treatments)
            return str(treatments)
        return ''


class PredictUploadSerializer(serializers.Serializer):
    image = serializers.ImageField()
    device_information = serializers.CharField(required=False, allow_blank=True, default='')
    location_data = serializers.CharField(required=False, allow_blank=True, default='')

    def validate_image(self, value):
        # Max 10 MB
        max_size = 10 * 1024 * 1024
        if value.size > max_size:
            raise serializers.ValidationError('Image file too large. Maximum size is 10 MB.')
        # Validate content type
        allowed_types = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
        if value.content_type not in allowed_types:
            raise serializers.ValidationError(
                f'Unsupported image format "{value.content_type}". '
                f'Allowed: {", ".join(allowed_types)}'
            )
        return value
