from django.urls import path
from .views import (
    CropListView,
    DashboardStatsView,
    DiseaseDetailView,
    DiseaseListView,
    MedicineDetailView,
    MedicineListView,
    PredictView,
    ScanHistoryDetailView,
    ScanHistoryListView,
)
from . import admin_views

urlpatterns = [
    # User dashboard
    path('dashboard/', DashboardStatsView.as_view(), name='dashboard'),

    # Prediction
    path('predict/', PredictView.as_view(), name='predict'),
    path('predictions/', PredictView.as_view(), name='predictions'),
    path('predictions/<int:pk>/', ScanHistoryDetailView.as_view(), name='prediction_detail'),

    # Scan history
    path('history/', ScanHistoryListView.as_view(), name='history_list'),
    path('history/<int:pk>/', ScanHistoryDetailView.as_view(), name='history_detail'),

    # Disease library
    path('crops/', CropListView.as_view(), name='crop_list'),
    path('diseases/', DiseaseListView.as_view(), name='disease_list'),
    path('diseases/<int:pk>/', DiseaseDetailView.as_view(), name='disease_detail'),

    # Medicines
    path('medicines/', MedicineListView.as_view(), name='medicine_list'),
    path('medicines/<int:pk>/', MedicineDetailView.as_view(), name='medicine_detail'),

    # Admin endpoints
    path('admin/scans/', admin_views.AdminScanListView.as_view(), name='admin_scans'),
    path('admin/scans/<int:pk>/', admin_views.AdminScanActionView.as_view(), name='admin_scan_action'),
    path('admin/predict/', admin_views.AdminPredictView.as_view(), name='admin_predict'),
    path('admin/diseases/', admin_views.AdminDiseaseListCreateView.as_view(), name='admin_diseases_list'),
    path('admin/diseases/<int:pk>/', admin_views.AdminDiseaseRetrieveUpdateDestroyView.as_view(), name='admin_diseases_detail'),
    path('admin/medicines/', admin_views.AdminMedicineListCreateView.as_view(), name='admin_medicines_list'),
    path('admin/medicines/<int:pk>/', admin_views.AdminMedicineRetrieveUpdateDestroyView.as_view(), name='admin_medicines_detail'),
]
