from django.contrib import admin
from .models import Crop, Disease, DiseasePrediction, Notification, ScanHistory, Medicine, DiseaseMedicineMapping

admin.site.register(Crop)
admin.site.register(Disease)
admin.site.register(Medicine)
admin.site.register(DiseaseMedicineMapping)
admin.site.register(ScanHistory)
admin.site.register(DiseasePrediction)
admin.site.register(Notification)
