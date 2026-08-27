from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

User = get_user_model()


class AccountAPITests(APITestCase):
    def setUp(self):
        self.signup_url = reverse('signup')
        self.login_url = reverse('login')
        self.me_url = reverse('me')
        self.change_password_url = reverse('change-password')
        self.verify_otp_url = reverse('verify-otp')

        self.user_data = {
            'name': 'Ram Bahadur',
            'email': 'farmer@agrivision.com',
            'phone': '9841234567',
            'password': 'Password123!',
            'confirm_password': 'Password123!',
        }

    def test_signup_and_login_flow(self):
        # Test Signup
        response = self.client.post(self.signup_url, self.user_data, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('access', response.data)
        self.assertIn('dev_otp', response.data)

        otp = response.data['dev_otp']
        email = self.user_data['email']

        # Test Verify OTP
        verify_resp = self.client.post(self.verify_otp_url, {'email': email, 'code': otp}, format='json')
        self.assertEqual(verify_resp.status_code, status.HTTP_200_OK)

        # Test Login
        login_resp = self.client.post(
            self.login_url,
            {'email': self.user_data['email'], 'password': self.user_data['password']},
            format='json',
        )
        self.assertEqual(login_resp.status_code, status.HTTP_200_OK)
        self.assertIn('access', login_resp.data)

        access_token = login_resp.data['access']
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access_token}')

        # Test Me endpoint
        me_resp = self.client.get(self.me_url)
        self.assertEqual(me_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(me_resp.data['email'], self.user_data['email'])

    def test_change_password(self):
        user = User.objects.create_user(
            username='testpwd@agrivision.com',
            email='testpwd@agrivision.com',
            full_name='Test User',
            password='OldPassword123!',
        )
        self.client.force_authenticate(user=user)

        response = self.client.post(
            self.change_password_url,
            {
                'current_password': 'OldPassword123!',
                'new_password': 'NewPassword123!',
                'confirm_password': 'NewPassword123!',
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(user.check_password('NewPassword123!'))

    def test_favourites_flow(self):
        user = User.objects.create_user(
            username='favuser@agrivision.com',
            email='favuser@agrivision.com',
            full_name='Fav User',
            password='Password123!',
        )
        self.client.force_authenticate(user=user)
        from apps.scans.models import Crop, Disease
        crop = Crop.objects.create(name='Tomato')
        disease = Disease.objects.create(crop=crop, name='Tomato___Late_blight')

        fav_url = reverse('favourites_list')
        response = self.client.post(fav_url, {'disease_id': disease.id, 'notes': 'Check organic spray'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)

        list_resp = self.client.get(fav_url)
        self.assertEqual(list_resp.status_code, status.HTTP_200_OK)
        self.assertEqual(len(list_resp.data), 1)

