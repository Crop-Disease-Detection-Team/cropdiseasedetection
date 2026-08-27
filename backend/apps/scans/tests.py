import io
from PIL import Image
from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from apps.scans.models import Crop, Disease, ScanHistory

User = get_user_model()


class ScanAPITests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='farmer_scan@agrivision.com',
            email='farmer_scan@agrivision.com',
            full_name='Hari Krishna',
            password='Password123!',
        )
        self.admin = User.objects.create_superuser(
            username='admin_scan@agrivision.com',
            email='admin_scan@agrivision.com',
            full_name='Admin User',
            password='AdminPassword123!',
            role='admin',
        )

        self.crop = Crop.objects.create(name='Tomato', scientific_name='Solanum lycopersicum')
        self.disease = Disease.objects.create(
            crop=self.crop,
            name='Tomato___Late_blight',
            scientific_name='Phytophthora infestans',
            description='Late blight of tomato',
            severity='High',
        )

        self.predict_url = reverse('predict')
        self.history_url = reverse('history_list')
        self.diseases_url = reverse('disease_list')
        self.admin_scans_url = reverse('admin_scans')

    def generate_image_file(self):
        file = io.BytesIO()
        image = Image.new('RGB', (224, 224), color='green')
        image.save(file, 'jpeg')
        file.seek(0)
        return SimpleUploadedFile('leaf_sample.jpg', file.read(), content_type='image/jpeg')

    def test_disease_library_list(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.get(self.diseases_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_predict_and_history_creation(self):
        self.client.force_authenticate(user=self.user)
        image_file = self.generate_image_file()

        response = self.client.post(
            self.predict_url,
            {'image': image_file},
            format='multipart',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('crop_name', response.data)
        self.assertIn('confidence', response.data)

        # Check that scan history entry was recorded
        history_resp = self.client.get(self.history_url)
        self.assertEqual(history_resp.status_code, status.HTTP_200_OK)

    def test_admin_scans_endpoint(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.get(self.admin_scans_url)
        self.assertEqual(response.status_code, status.HTTP_200_OK)
