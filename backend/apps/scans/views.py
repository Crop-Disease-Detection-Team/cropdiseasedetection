import logging

from django.db.models import Q
from rest_framework import generics, permissions, status
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework.views import APIView

from .ai_service import predict, CONFIDENCE_THRESHOLD
from .models import Crop, Disease, DiseasePrediction, Medicine, ScanHistory
from .serializers import (
    CropSerializer,
    DiseaseListSerializer,
    DiseaseSerializer,
    MedicineSerializer,
    PredictUploadSerializer,
    ScanHistorySerializer,
)

logger = logging.getLogger(__name__)


# ── User Dashboard ────────────────────────────────────────────────────────

class DashboardStatsView(APIView):
    def get(self, request):
        scans = request.user.scans.all()
        recent = ScanHistorySerializer(
            scans.select_related('disease__crop').order_by('-created_at')[:5],
            many=True,
            context={'request': request},
        ).data
        return Response({
            'total_scans': scans.count(),
            'healthy_count': scans.filter(healthy_probability__gte=0.5).count(),
            'diseased_count': scans.filter(disease_probability__gte=0.5).count(),
            'recent': recent,
        })


# ── Disease Library ───────────────────────────────────────────────────────

class CropListView(generics.ListAPIView):
    """List all crops (browsable disease library root)."""
    queryset = Crop.objects.all().order_by('name')
    serializer_class = CropSerializer
    permission_classes = [permissions.IsAuthenticated]


class DiseaseListView(generics.ListAPIView):
    """List diseases. Supports ?crop=<id> and ?search=<term>."""
    serializer_class = DiseaseListSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        qs = Disease.objects.select_related('crop').order_by('name')
        crop_id = self.request.query_params.get('crop')
        search = self.request.query_params.get('search')
        if crop_id:
            qs = qs.filter(crop_id=crop_id)
        if search:
            qs = qs.filter(
                Q(name__icontains=search)
                | Q(crop__name__icontains=search)
                | Q(description__icontains=search)
            )
        return qs


class DiseaseDetailView(generics.RetrieveAPIView):
    """Full disease detail including medicines."""
    queryset = Disease.objects.select_related('crop').prefetch_related(
        'medicine_mappings__medicine'
    )
    serializer_class = DiseaseSerializer
    permission_classes = [permissions.IsAuthenticated]


class MedicineListView(generics.ListAPIView):
    """List all medicines."""
    queryset = Medicine.objects.all().order_by('name')
    serializer_class = MedicineSerializer
    permission_classes = [permissions.IsAuthenticated]


class MedicineDetailView(generics.RetrieveAPIView):
    """Single medicine detail."""
    queryset = Medicine.objects.all()
    serializer_class = MedicineSerializer
    permission_classes = [permissions.IsAuthenticated]


# ── Prediction ────────────────────────────────────────────────────────────

class PredictView(APIView):
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = PredictUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        image = serializer.validated_data['image']
        device_info = serializer.validated_data.get('device_information', '')
        location = serializer.validated_data.get('location_data', '')

        # Save the scan record first (image on disk needed for inference)
        scan = ScanHistory.objects.create(
            user=request.user,
            image=image,
            confidence=0,
            device_information=device_info,
            location_data=location,
        )

        # Run AI inference
        try:
            result = predict(scan.image.path)
        except Exception:
            logger.exception('Prediction failed for scan %s', scan.id)
            scan.delete()
            return Response(
                {'detail': 'Prediction failed. Please try again.'},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR,
            )

        confidence = result.get('confidence', 0)
        is_healthy = result.get('is_healthy', False)
        class_label = result.get('class_label', '')

        # Low confidence — encourage retake
        if confidence < CONFIDENCE_THRESHOLD:
            scan.raw_response = result
            scan.confidence = confidence
            scan.save()
            return Response({
                'scan_id': scan.id,
                'low_confidence': True,
                'confidence': round(confidence * 100, 1),
                'message': 'Unable to identify. Please upload a clearer image.',
                'top_predictions': result.get('top_predictions', []),
            }, status=status.HTTP_200_OK)

        # Look up disease in the database
        disease = Disease.objects.filter(name=class_label).select_related('crop').first()
        if not disease:
            # Try to find by a cleaned-up version of the label
            crop_name = result.get('crop_name', '')
            disease_name = result.get('disease_name', '')
            disease = Disease.objects.filter(
                Q(name__icontains=disease_name) & Q(crop__name__icontains=crop_name)
            ).select_related('crop').first()

        # Auto-create if still not found (for mock/dev mode)
        if not disease and not is_healthy:
            crop, _ = Crop.objects.get_or_create(
                name=result.get('crop_name', 'Unknown'),
                defaults={'scientific_name': ''},
            )
            disease, _ = Disease.objects.get_or_create(
                name=class_label,
                defaults={
                    'crop': crop,
                    'description': f'Auto-created for {class_label}',
                    'severity': 'Medium',
                },
            )

        # Update scan with results
        scan.disease = disease
        scan.confidence = confidence
        scan.healthy_probability = result.get('healthy_probability', 0)
        scan.disease_probability = result.get('disease_probability', confidence)
        scan.raw_response = result
        scan.save()

        DiseasePrediction.objects.update_or_create(
            scan=scan, defaults={'payload': result}
        )

        # Build enriched response
        response_data = {
            'scan_id': scan.id,
            'low_confidence': False,
            'crop_name': result.get('crop_name', ''),
            'disease_name': result.get('disease_name', 'Healthy'),
            'is_healthy': is_healthy,
            'confidence': round(confidence * 100, 1),
            'top_predictions': [
                {
                    'name': p.get('name', ''),
                    'confidence': round(p.get('confidence', 0) * 100, 1),
                }
                for p in result.get('top_predictions', [])
            ],
            'scan_date': scan.created_at.isoformat(),
        }

        if is_healthy:
            crop_name = result.get('crop_name', 'your crop')
            response_data.update({
                'message': f'No disease detected. Your {crop_name} appears healthy!',
                'general_care': [
                    'Water regularly and maintain consistent soil moisture.',
                    'Use balanced NPK fertilizer during the growing season.',
                    'Monitor for pests and remove any damaged leaves promptly.',
                    'Ensure adequate spacing between plants for air circulation.',
                    'Rotate crops annually to prevent soil-borne disease build-up.',
                ],
            })
        elif disease:
            # Fetch medicines for this disease
            medicine_data = []
            for mapping in disease.medicine_mappings.select_related('medicine').all():
                med = mapping.medicine
                medicine_data.append({
                    'name': med.name,
                    'type': med.type,
                    'active_ingredients': med.active_ingredients,
                    'dosage_guidance': med.dosage_guidance,
                    'application_method': med.application_method,
                    'safety_precautions': med.safety_precautions,
                })

            response_data.update({
                'crop_scientific_name': disease.crop.scientific_name if disease.crop else '',
                'disease_scientific_name': disease.scientific_name,
                'description': disease.description,
                'symptoms': disease.symptoms,
                'causes': disease.causes,
                'organic_treatments': disease.organic_treatments,
                'chemical_treatments': disease.chemical_treatments,
                'prevention_tips': disease.prevention_tips,
                'severity': disease.severity,
                'affected_parts': disease.affected_parts,
                'duration': disease.duration,
                'weather': disease.weather,
                'regional_recommendation': disease.regional_recommendation,
                'sample_image': disease.sample_image,
                'medicines': medicine_data,
            })

        # Also include serialized scan history for the Flutter client
        response_data['history'] = ScanHistorySerializer(
            scan, context={'request': request}
        ).data

        return Response(response_data, status=status.HTTP_201_CREATED)


# ── Scan History ──────────────────────────────────────────────────────────

class ScanHistoryListView(generics.ListAPIView):
    serializer_class = ScanHistorySerializer

    def get_queryset(self):
        return self.request.user.scans.select_related('disease__crop').order_by('-created_at')


class ScanHistoryDetailView(generics.RetrieveDestroyAPIView):
    serializer_class = ScanHistorySerializer

    def get_queryset(self):
        return self.request.user.scans.select_related('disease__crop').order_by('-created_at')
