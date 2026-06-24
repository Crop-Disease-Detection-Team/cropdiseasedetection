import os
from datetime import timedelta
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

class Config:
    # ============================================
    # FLASK CONFIGURATION
    # ============================================
    SECRET_KEY = os.environ.get('SECRET_KEY', 'your-flask-secret-key')
    DEBUG = os.environ.get('DEBUG', 'True').lower() == 'true'
    
    # ============================================
    # DATABASE CONFIGURATION (MySQL)
    # ============================================
    DB_HOST = os.environ.get('DB_HOST', 'localhost')
    DB_USER = os.environ.get('DB_USER', 'root')
    DB_PASSWORD = os.environ.get('DB_PASSWORD', 'bikram123')
    DB_NAME = os.environ.get('DB_NAME', 'crop_disease_db')
    
    SQLALCHEMY_DATABASE_URI = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}/{DB_NAME}?charset=utf8mb4"
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_size': 10,
        'pool_recycle': 3600,
        'pool_pre_ping': True,
    }
    
    # ============================================
    # JWT CONFIGURATION
    # ============================================
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'your-super-secure-jwt-secret-key')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=1)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(days=30)
    JWT_TOKEN_LOCATION = ['headers']
    JWT_HEADER_NAME = 'Authorization'
    JWT_HEADER_TYPE = 'Bearer'
    
    # ============================================
    # FILE UPLOAD CONFIGURATION
    # ============================================
    UPLOAD_FOLDER = 'uploads'
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'heic', 'webp'}
    
    # Create upload folders if they don't exist
    os.makedirs(UPLOAD_FOLDER, exist_ok=True)
    os.makedirs(os.path.join(UPLOAD_FOLDER, 'profiles'), exist_ok=True)
    os.makedirs(os.path.join(UPLOAD_FOLDER, 'scans'), exist_ok=True)
    
    # ============================================
    # MODEL CONFIGURATION
    # ============================================
    MODEL_PATH = os.environ.get('MODEL_PATH', 'models/best_model.pth')
    CLASS_NAMES_PATH = os.environ.get('CLASS_NAMES_PATH', 'models/class_names.json')
    IMG_SIZE = 224
    CONFIDENCE_THRESHOLD = int(os.environ.get('CONFIDENCE_THRESHOLD', 70))
    
    # ============================================
    # EMAIL CONFIGURATION
    # ============================================
    MAIL_SERVER = os.environ.get('SMTP_SERVER', 'smtp.gmail.com')
    MAIL_PORT = int(os.environ.get('SMTP_PORT', 587))
    MAIL_USERNAME = os.environ.get('EMAIL_USER', 'bikram204sharma@gmail.com')
    MAIL_PASSWORD = os.environ.get('EMAIL_PASSWORD', '')
    MAIL_USE_TLS = True
    MAIL_USE_SSL = False
    MAIL_DEFAULT_SENDER = MAIL_USERNAME
    ADMIN_EMAIL = os.environ.get('ADMIN_EMAIL', 'bikram204sharma@gmail.com')
    
    # ============================================
    # CORS CONFIGURATION
    # ============================================
    CORS_ORIGINS = [
        'http://localhost:5500',
        'http://127.0.0.1:5500',
        'http://localhost:3000',
        'http://localhost:5000',
        'http://192.168.0.108:5500',
        'http://192.168.1.100:5500'
    ]
    
    # Also allow from comma-separated list in .env
    env_origins = os.environ.get('CORS_ORIGINS', '')
    if env_origins:
        CORS_ORIGINS.extend([origin.strip() for origin in env_origins.split(',')])
    
    # ============================================
    # RATE LIMITING
    # ============================================
    RATELIMIT_DEFAULT = os.environ.get('RATELIMIT_DEFAULT', '100 per day')
    RATELIMIT_STORAGE_URL = os.environ.get('RATELIMIT_STORAGE_URL', 'memory://')
    
    # ============================================
    # SESSION SECURITY
    # ============================================
    SESSION_COOKIE_SECURE = False  # Set to True in production with HTTPS
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'
    REMEMBER_COOKIE_SECURE = False
    REMEMBER_COOKIE_HTTPONLY = True
    REMEMBER_COOKIE_SAMESITE = 'Lax'


class DevelopmentConfig(Config):
    """Development configuration"""
    DEBUG = True
    TESTING = False
    # Allow all origins in development
    CORS_ORIGINS = Config.CORS_ORIGINS + ['*']
    # Disable HTTPS in development
    SESSION_COOKIE_SECURE = False
    REMEMBER_COOKIE_SECURE = False


class ProductionConfig(Config):
    """Production configuration"""
    DEBUG = False
    TESTING = False
    # Enable HTTPS in production
    SESSION_COOKIE_SECURE = True
    REMEMBER_COOKIE_SECURE = True
    # Stricter CORS for production
    CORS_ORIGINS = [
        'https://yourdomain.com',
        'https://www.yourdomain.com'
    ]
    # Production database pool
    SQLALCHEMY_ENGINE_OPTIONS = {
        'pool_size': 20,
        'pool_recycle': 3600,
        'pool_pre_ping': True,
        'pool_timeout': 30,
    }


class TestingConfig(Config):
    """Testing configuration"""
    TESTING = True
    DEBUG = True
    # Use in-memory SQLite for testing
    SQLALCHEMY_DATABASE_URI = "sqlite:///:memory:"
    # Disable file uploads in testing
    UPLOAD_FOLDER = 'test_uploads'
    # Shorter tokens for testing
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=5)
    JWT_REFRESH_TOKEN_EXPIRES = timedelta(minutes=30)


# ============================================
# CONFIGURATION HELPER FUNCTIONS
# ============================================

def get_config(config_name='development'):
    """Get configuration by name"""
    configs = {
        'development': DevelopmentConfig,
        'production': ProductionConfig,
        'testing': TestingConfig
    }
    return configs.get(config_name, DevelopmentConfig)


def validate_config(app_config):
    """Validate critical configuration settings"""
    warnings = []
    errors = []
    
    # Check JWT secret key
    if app_config.JWT_SECRET_KEY == 'your-super-secure-jwt-secret-key':
        warnings.append(" WARNING: Using default JWT_SECRET_KEY. Change this in production!")
    
    # Check Flask secret key
    if app_config.SECRET_KEY == 'your-flask-secret-key':
        warnings.append("WARNING: Using default SECRET_KEY. Change this in production!")
    
    # Check email password in production
    if not app_config.MAIL_PASSWORD:
        warnings.append(" WARNING: EMAIL_PASSWORD not set. Email notifications will not work!")
    
    # Check database connection
    if app_config.DB_PASSWORD == 'bikram123' and not app_config.DEBUG:
        warnings.append(" WARNING: Using default database password. Change this in production!")
    
    # Print warnings
    for warning in warnings:
        print(warning)
    
    return len(errors) == 0


def print_config_summary(app_config):
    """Print configuration summary on startup"""
    print("\n" + "="*60)
    print(" CONFIGURATION SUMMARY")
    print("="*60)
    print(f" Environment: {'Development' if app_config.DEBUG else 'Production'}")
    print(f"Database: {app_config.SQLALCHEMY_DATABASE_URI.split('@')[-1] if '@' in app_config.SQLALCHEMY_DATABASE_URI else 'SQLite'}")
    print(f"Email: {'Configured' if app_config.MAIL_PASSWORD else 'Not configured'}")
    print(f" Upload folder: {app_config.UPLOAD_FOLDER}")
    print(f" JWT Expiry: {app_config.JWT_ACCESS_TOKEN_EXPIRES}")
    print(f" CORS Origins: {len(app_config.CORS_ORIGINS)} origins")
    print("="*60 + "\n")