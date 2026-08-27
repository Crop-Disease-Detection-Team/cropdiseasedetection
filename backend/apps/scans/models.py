from django.conf import settings
from django.db import models


class Crop(models.Model):
    name = models.CharField(max_length=120, unique=True)
    scientific_name = models.CharField(max_length=200, blank=True)

    def __str__(self):
        return self.name


class Disease(models.Model):
    SEVERITY_CHOICES = (
        ('Low', 'Low'),
        ('Medium', 'Medium'),
        ('High', 'High'),
        ('Critical', 'Critical'),
    )

    crop = models.ForeignKey(Crop, on_delete=models.CASCADE, related_name='diseases')
    name = models.CharField(max_length=150, unique=True)
    scientific_name = models.CharField(max_length=200, blank=True)
    family = models.CharField(max_length=150, blank=True)
    description = models.TextField(blank=True)
    symptoms = models.JSONField(default=list, blank=True)
    causes = models.JSONField(default=list, blank=True)
    organic_treatments = models.JSONField(default=list, blank=True)
    chemical_treatments = models.JSONField(default=list, blank=True)
    prevention_tips = models.JSONField(default=list, blank=True)
    affected_parts = models.JSONField(default=list, blank=True)
    duration = models.CharField(max_length=120, blank=True)
    weather = models.CharField(max_length=120, blank=True)
    severity = models.CharField(max_length=20, choices=SEVERITY_CHOICES, default='Medium')
    sample_image = models.URLField(blank=True)
    regional_recommendation = models.TextField(blank=True)
    nearby_agricultural_office = models.CharField(max_length=255, blank=True)

    def __str__(self):
        return self.name


class ScanHistory(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='scans')
    image = models.ImageField(upload_to='scans/')
    disease = models.ForeignKey(Disease, on_delete=models.SET_NULL, null=True, blank=True)
    confidence = models.FloatField()
    healthy_probability = models.FloatField(default=0)
    disease_probability = models.FloatField(default=0)
    raw_response = models.JSONField(default=dict, blank=True)
    device_information = models.CharField(max_length=255, blank=True)
    location_data = models.CharField(max_length=255, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        disease_name = self.disease.name if self.disease else 'Pending'
        return f"{self.user.email} - {disease_name} at {self.created_at}"


class DiseasePrediction(models.Model):
    scan = models.OneToOneField(ScanHistory, on_delete=models.CASCADE, related_name='prediction')
    payload = models.JSONField(default=dict)


class Medicine(models.Model):
    name = models.CharField(max_length=150)
    type = models.CharField(max_length=50, choices=(('organic', 'Organic'), ('chemical', 'Chemical')))
    active_ingredients = models.CharField(max_length=255, blank=True)
    manufacturer = models.CharField(max_length=150, blank=True)
    dosage_guidance = models.CharField(max_length=255, blank=True)
    application_method = models.CharField(max_length=255, blank=True)
    safety_precautions = models.TextField(blank=True)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name

class DiseaseMedicineMapping(models.Model):
    disease = models.ForeignKey(Disease, on_delete=models.CASCADE, related_name='medicine_mappings')
    medicine = models.ForeignKey(Medicine, on_delete=models.CASCADE, related_name='disease_mappings')

    class Meta:
        db_table = 'disease_medicine_mapping'
        unique_together = ('disease', 'medicine')

    def __str__(self):
        return f"{self.disease.name} - {self.medicine.name}"


class Notification(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='notifications')
    title = models.CharField(max_length=140)
    body = models.TextField()
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
