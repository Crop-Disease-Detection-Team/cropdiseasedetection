from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.parsers import MultiPartParser, FormParser
from django.db.models import Q

from apps.common.permissions import IsAdminUserRole
from apps.common.utils import log_admin_action
from .models import ScanHistory, Disease, Medicine, DiseaseMedicineMapping, Crop
from .serializers import ScanHistorySerializer, DiseaseSerializer, PredictUploadSerializer, MedicineSerializer
from .ai_service import predict


class AdminScanListView(generics.ListAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserRole]
    serializer_class = ScanHistorySerializer

    def get_queryset(self):
        queryset = ScanHistory.objects.all().order_by('-created_at')
        search = self.request.query_params.get('search', None)
        disease_id = self.request.query_params.get('disease', None)
        if search:
            queryset = queryset.filter(Q(user__email__icontains=search) | Q(disease__name__icontains=search))
        if disease_id:
            queryset = queryset.filter(disease_id=disease_id)
        return queryset


class AdminScanActionView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserRole]

    def delete(self, request, pk):
        try:
            scan = ScanHistory.objects.get(pk=pk)
            scan.delete()
            log_admin_action(request.user, 'Deleted Scan', f'Scan ID: {pk}')
            return Response({'message': 'Scan deleted.'})
        except ScanHistory.DoesNotExist:
            return Response({'detail': 'Scan not found.'}, status=status.HTTP_404_NOT_FOUND)


class AdminPredictView(APIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserRole]
    parser_classes = [MultiPartParser, FormParser]

    def post(self, request):
        serializer = PredictUploadSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        image = serializer.validated_data['image']
        
        # We don't save to ScanHistory for admins, or we save it but maybe flag it? 
        # Requirement: "Admin should also be able to perform crop disease detection. Save prediction to scan history."
        scan = ScanHistory.objects.create(user=request.user, image=image, confidence=0)

        result = predict(scan.image.path)
        class_label = result.get('class_label', '')
        crop_name = result.get('crop_name', 'Unknown')
        is_healthy = result.get('is_healthy', False)

        crop, _ = Crop.objects.get_or_create(
            name=crop_name, defaults={'scientific_name': ''}
        )
        disease = Disease.objects.filter(name=class_label).first()
        if not disease and not is_healthy:
            disease, _ = Disease.objects.get_or_create(
                name=class_label,
                defaults={
                    'crop': crop,
                    'description': f'Auto-created for {class_label}',
                    'severity': 'Medium',
                },
            )

        scan.disease = disease
        scan.confidence = result.get('confidence', 0)
        scan.healthy_probability = result.get('healthy_probability', 0)
        scan.disease_probability = result.get('disease_probability', 0)
        scan.raw_response = result
        scan.save()

        detected = disease.name if disease else 'Healthy'
        log_admin_action(request.user, 'Admin Performed Scan', f'Detected: {detected}')

        history = ScanHistorySerializer(scan, context={'request': request}).data
        return Response({'scan_id': scan.id, 'history': history, **result}, status=status.HTTP_201_CREATED)


# ── Disease Management (Admin) ───────────────────────────────────────────

class AdminDiseaseListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserRole]
    serializer_class = DiseaseSerializer

    def get_queryset(self):
        qs = Disease.objects.select_related('crop').all().order_by('name')
        crop_id = self.request.query_params.get('crop')
        search = self.request.query_params.get('search')
        if crop_id:
            qs = qs.filter(crop_id=crop_id)
        if search:
            qs = qs.filter(Q(name__icontains=search) | Q(crop__name__icontains=search))
        return qs

    def perform_create(self, serializer):
        disease = serializer.save()
        log_admin_action(self.request.user, 'Created Disease', f'Disease: {disease.name}')


class AdminDiseaseRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserRole]
    serializer_class = DiseaseSerializer
    queryset = Disease.objects.all()

    def perform_update(self, serializer):
        disease = serializer.save()
        log_admin_action(self.request.user, 'Updated Disease', f'Disease: {disease.name}')

    def perform_destroy(self, instance):
        name = instance.name
        instance.delete()
        log_admin_action(self.request.user, 'Deleted Disease', f'Disease: {name}')


# ── Medicine Management (Admin) ───────────────────────────────────────────

class AdminMedicineListCreateView(generics.ListCreateAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserRole]
    serializer_class = MedicineSerializer

    def get_queryset(self):
        qs = Medicine.objects.all().order_by('name')
        search = self.request.query_params.get('search')
        if search:
            qs = qs.filter(Q(name__icontains=search) | Q(active_ingredients__icontains=search))
        return qs

    def perform_create(self, serializer):
        medicine = serializer.save()
        log_admin_action(self.request.user, 'Created Medicine', f'Medicine: {medicine.name}')


class AdminMedicineRetrieveUpdateDestroyView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [permissions.IsAuthenticated, IsAdminUserRole]
    serializer_class = MedicineSerializer
    queryset = Medicine.objects.all()

    def perform_update(self, serializer):
        medicine = serializer.save()
        log_admin_action(self.request.user, 'Updated Medicine', f'Medicine: {medicine.name}')

    def perform_destroy(self, instance):
        name = instance.name
        instance.delete()
        log_admin_action(self.request.user, 'Deleted Medicine', f'Medicine: {name}')

