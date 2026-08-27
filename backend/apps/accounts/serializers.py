from django.contrib.auth import authenticate
from rest_framework import serializers

from .models import User, UserFavourite
from apps.scans.serializers import DiseaseSerializer


class SignupSerializer(serializers.ModelSerializer):
    name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    full_name = serializers.CharField(required=False, allow_blank=True)
    username = serializers.CharField(required=False, allow_blank=True)
    district = serializers.CharField(required=False, allow_blank=True)
    address = serializers.CharField(write_only=True, required=False, allow_blank=True)
    password = serializers.CharField(write_only=True, min_length=8)
    confirm_password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['name', 'full_name', 'username', 'email', 'phone', 'district', 'address', 'password', 'confirm_password']

    def validate(self, attrs):
        if attrs['password'] != attrs['confirm_password']:
            raise serializers.ValidationError({'confirm_password': 'Passwords do not match.'})
        return attrs

    def create(self, validated_data):
        name = validated_data.pop('name', '')
        full_name = validated_data.pop('full_name', '') or name
        district = validated_data.pop('district', '') or validated_data.pop('address', '')
        validated_data.pop('confirm_password')
        password = validated_data.pop('password')
        username = validated_data.pop('username', '')
        if not username:
            username = validated_data['email'].split('@')[0]
        
        user = User(
            full_name=full_name,
            district=district,
            username=username,
            **validated_data
        )
        user.set_password(password)
        user.is_active = True
        user.save()
        return user


class LoginSerializer(serializers.Serializer):
    email = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        identifier = attrs['email']
        password = attrs['password']

        user = None
        if '@' in identifier:
            user = authenticate(username=identifier, password=password)
        else:
            user_obj = User.objects.filter(username=identifier).first()
            if user_obj:
                user = authenticate(username=user_obj.email, password=password)

        if not user:
            raise serializers.ValidationError('Invalid credentials.')
        attrs['user'] = user
        return attrs


class OTPVerifySerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=6)


class ForgotPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()


class ResetPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField()
    code = serializers.CharField(max_length=6)
    password = serializers.CharField(min_length=8)


class ChangePasswordSerializer(serializers.Serializer):
    current_password = serializers.CharField()
    new_password = serializers.CharField(min_length=8)
    confirm_password = serializers.CharField()

    def validate(self, attrs):
        if attrs['new_password'] != attrs['confirm_password']:
            raise serializers.ValidationError({'confirm_password': 'Passwords do not match.'})
        return attrs


class UserSerializer(serializers.ModelSerializer):
    name = serializers.CharField(source='full_name', read_only=True)
    address = serializers.CharField(source='district', read_only=True)

    class Meta:
        model = User
        fields = [
            'id',
            'name',
            'full_name',
            'username',
            'email',
            'phone',
            'district',
            'address',
            'avatar',
            'is_email_verified',
            'role',
            'language',
        ]
        read_only_fields = ['id', 'email', 'name', 'address', 'avatar', 'is_email_verified', 'role']


class UserFavouriteSerializer(serializers.ModelSerializer):
    disease_id = serializers.IntegerField(write_only=True, required=False)
    disease_detail = DiseaseSerializer(source='disease', read_only=True)

    class Meta:
        model = UserFavourite
        fields = ['id', 'user', 'disease', 'disease_id', 'disease_detail', 'notes', 'saved_at']
        read_only_fields = ['id', 'user', 'saved_at']
        extra_kwargs = {'disease': {'required': False}}



