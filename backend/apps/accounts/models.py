import random
from datetime import timedelta

from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone


class User(AbstractUser):
    ROLE_CHOICES = (
        ('user', 'User'),
        ('admin', 'Admin'),
    )

    username = models.CharField(max_length=150, unique=True, null=True, blank=True)
    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=120)
    phone = models.CharField(max_length=25, blank=True)
    district = models.CharField(max_length=100, blank=True)
    avatar = models.URLField(blank=True)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='user')
    is_email_verified = models.BooleanField(default=False)
    dark_mode = models.BooleanField(default=False)
    language = models.CharField(default='en', max_length=10)
    verification_otp = models.CharField(max_length=6, null=True, blank=True)
    otp_expires_at = models.DateTimeField(null=True, blank=True)
    otp_last_sent = models.DateTimeField(null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['full_name']

    def __str__(self):
        return self.email

    @property
    def name(self):
        return self.full_name

    @property
    def address(self):
        return self.district

    def generate_otp(self):
        otp = str(random.randint(100000, 999999))
        self.verification_otp = otp
        self.otp_expires_at = timezone.now() + timedelta(minutes=10)
        self.otp_last_sent = timezone.now()
        self.save(update_fields=['verification_otp', 'otp_expires_at', 'otp_last_sent'])
        return otp


class Feedback(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='feedback')
    message = models.TextField()
    status = models.CharField(max_length=20, default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"Feedback from {self.user.email} - {self.status}"


class EmailVerification(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='email_tokens')
    token = models.CharField(max_length=128)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)


class PasswordReset(models.Model):
    PURPOSE_CHOICES = (
        ('signup', 'Signup'),
        ('reset', 'Reset'),
    )

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='otps')
    code = models.CharField(max_length=6)
    purpose = models.CharField(max_length=20, choices=PURPOSE_CHOICES)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)


class UserFavourite(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favourites')
    disease = models.ForeignKey('scans.Disease', on_delete=models.CASCADE, related_name='favourited_by')
    notes = models.TextField(blank=True, default='')
    saved_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'user_favourites'
        unique_together = ('user', 'disease')

    def __str__(self):
        return f"{self.user.email} - {self.disease.name}"

