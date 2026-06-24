from flask import Flask, jsonify, send_from_directory, render_template, redirect, url_for
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from config import DevelopmentConfig, ProductionConfig, get_config, validate_config, print_config_summary
from models import db, bcrypt, TokenBlacklist
import os
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def create_app(config_name='development'):
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

    app = Flask(__name__,
                template_folder=os.path.join(base_dir, 'templates'),
                static_folder=os.path.join(base_dir, 'static'))

    if config_name == 'production':
        app.config.from_object(ProductionConfig)
    else:
        app.config.from_object(DevelopmentConfig)

    CORS(app,
         origins=app.config.get('CORS_ORIGINS', ['http://localhost:5500', 'http://127.0.0.1:5500', 'http://localhost:5000']),
         supports_credentials=True,
         allow_headers=['Content-Type', 'Authorization'],
         methods=['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'])

    db.init_app(app)
    bcrypt.init_app(app)
    jwt = JWTManager(app)

    # ============================================
    # JWT CALLBACKS
    # ============================================

    @jwt.token_in_blocklist_loader
    def check_if_token_revoked(jwt_header, jwt_payload):
        jti = jwt_payload.get('jti')
        if jti:
            token = TokenBlacklist.query.filter_by(jti=jti).first()
            return token is not None
        return False

    @jwt.expired_token_loader
    def expired_token_callback(jwt_header, jwt_payload):
        return jsonify({'error': 'Token has expired', 'message': 'Please login again'}), 401

    @jwt.invalid_token_loader
    def invalid_token_callback(error):
        return jsonify({'error': 'Invalid token', 'message': str(error)}), 401

    @jwt.unauthorized_loader
    def unauthorized_callback(error):
        return jsonify({'error': 'Authorization token required', 'message': str(error)}), 401

    @jwt.revoked_token_loader
    def revoked_token_callback(jwt_header, jwt_payload):
        return jsonify({'error': 'Token has been revoked', 'message': 'Please login again'}), 401

    # Create upload folders
    os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
    os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], 'profiles'), exist_ok=True)
    os.makedirs(os.path.join(app.config['UPLOAD_FOLDER'], 'scans'), exist_ok=True)

    # Import and register blueprints
    from auth import auth_bp
    from user import user_bp
    from admin import admin_bp
    from disease import disease_bp
    from predict import predict_bp
    from feedback import feedback_bp

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(user_bp, url_prefix='/api/user')
    app.register_blueprint(admin_bp, url_prefix='/api/admin')
    app.register_blueprint(disease_bp, url_prefix='/api/disease')
    app.register_blueprint(predict_bp, url_prefix='/api')
    app.register_blueprint(feedback_bp, url_prefix='/api')

    # ============================================
    # SERVE STATIC FILES
    # ============================================

    @app.route('/statics/css/<path:filename>')
    def serve_css(filename):
        return send_from_directory(os.path.join(base_dir, 'statics', 'css'), filename)

    @app.route('/statics/js/<path:filename>')
    def serve_js(filename):
        return send_from_directory(os.path.join(base_dir, 'statics', 'js'), filename)

    @app.route('/statics/images/<path:filename>')
    def serve_images(filename):
        return send_from_directory(os.path.join(base_dir, 'statics', 'images'), filename)

    # ============================================
    # SERVE HTML PAGES
    # FIX: / now redirects to /login so visiting localhost:5000
    #      always lands on login when no token exists.
    #      The frontend requireAuth() in auth.js handles the
    #      redirect to dashboard if a valid token is present.
    # ============================================

    @app.route('/')
    def index():
        # Redirect root to login — the JS auth layer will
        # redirect to dashboard if already logged in
        return redirect(url_for('login_page'))

    @app.route('/login')
    def login_page():
        return render_template('login.html')

    @app.route('/register')
    def register_page():
        return render_template('register.html')

    @app.route('/verify-email')
    def verify_email_page():
        return render_template('verify-email.html')

    @app.route('/forgot-password')
    def forgot_password_page():
        return render_template('forgot-password.html')

    @app.route('/user-dashboard')
    def user_dashboard_page():
        return render_template('user-dashboard.html')

    @app.route('/admin-dashboard')
    def admin_dashboard_page():
        return render_template('admin-dashboard.html')

    @app.route('/predict')
    def predict_page():
        return render_template('predict.html')

    @app.route('/history')
    def history_page():
        return render_template('history.html')

    @app.route('/disease-detail')
    def disease_detail_page():
        return render_template('disease-detail.html')

    # ============================================
    # UPLOADS AND FILE SERVING
    # ============================================

    @app.route('/uploads/<filename>')
    def uploaded_file(filename):
        return send_from_directory(app.config['UPLOAD_FOLDER'], filename)

    @app.route('/uploads/profiles/<filename>')
    def uploaded_profile(filename):
        return send_from_directory(os.path.join(app.config['UPLOAD_FOLDER'], 'profiles'), filename)

    @app.route('/uploads/scans/<filename>')
    def uploaded_scan(filename):
        return send_from_directory(os.path.join(app.config['UPLOAD_FOLDER'], 'scans'), filename)

    @app.route('/static/samples/<filename>')
    def serve_samples(filename):
        return send_from_directory(os.path.join('static', 'samples'), filename)
    # ============================================
# SERVE OUTPUTS (metrics, logs, curves)
# ============================================

    @app.route('/outputs/<path:filename>')
    def serve_outputs(filename):
        """Serve files from the outputs directory (metrics, logs, plots)."""
        outputs_dir = os.path.join(base_dir, 'outputs')
    # Create the folder if it doesn't exist (prevents errors)
        os.makedirs(outputs_dir, exist_ok=True)
        return send_from_directory(outputs_dir, filename)
    # ============================================
    # API HEALTH CHECK
    # ============================================

    @app.route('/api/health', methods=['GET'])
    def health_check():
        return jsonify({
            'status': 'healthy',
            'message': 'Crop Disease Detection API is running',
            'version': '1.0.0',
            'token_blacklist': 'enabled'
        }), 200

    # ============================================
    # ERROR HANDLERS
    # ============================================

    @app.errorhandler(404)
    def not_found(error):
        return jsonify({'error': 'Resource not found'}), 404

    @app.errorhandler(500)
    def internal_error(error):
        logger.error(f"Internal server error: {str(error)}")
        return jsonify({'error': 'Internal server error'}), 500

    return app


if __name__ == '__main__':
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

    app = create_app()

    with app.app_context():
        db.create_all()
        logger.info("Database tables created/verified")

        from sqlalchemy import inspect
        inspector = inspect(db.engine)
        tables = inspector.get_table_names()
        logger.info(f"Tables found: {', '.join(tables)}")

        if 'token_blacklist' in tables:
            logger.info(" Token blacklist table ready")
        else:
            logger.info("  Token blacklist table not found - will be created")

        from models import User
        admin_email = "bikram204sharma@gmail.com"
        admin_user = User.query.filter_by(email=admin_email).first()
        if not admin_user:
            admin_user = User(
                name="Admin",
                email=admin_email,
                role="admin",
                is_active=True,
                email_verified=True
            )
            admin_user.set_password("Admin@123")
            db.session.add(admin_user)
            db.session.commit()
            logger.info(" Admin user created")
        else:
            logger.info(f" Admin user already exists: {admin_email}")

    print("\n" + "="*60)
    print("  CROP DISEASE DETECTION SYSTEM - BACKEND")
    print("="*60)
    print(f"  Server running at: http://localhost:5000")
    print(f"  Templates folder: {os.path.join(base_dir, 'templates')}")
    print(f"  Static folder:    {os.path.join(base_dir, 'static')}")
    print(f"  API Health:       http://localhost:5000/api/health")
    print(f"  Token Blacklist:  ENABLED")
    print(f"\n  Available Pages:")
    print(f"    Home:      http://localhost:5000/        → redirects to /login")
    print(f"    Login:     http://localhost:5000/login")
    print(f"    Register:  http://localhost:5000/register")
    print(f"    Verify:    http://localhost:5000/verify-email")
    print(f"    Forgot PW: http://localhost:5000/forgot-password")
    print(f"    User DB:   http://localhost:5000/user-dashboard")
    print(f"    Admin DB:  http://localhost:5000/admin-dashboard")
    print(f"    Predict:   http://localhost:5000/predict")
    print(f"    History:   http://localhost:5000/history")
    print(f"\n  Test Credentials:")
    print(f"    Admin: bikram204sharma@gmail.com / Admin@123")
    print(f"    User:  farmer@example.com / User@123")
    print("="*60 + "\n")

    app.run(host='0.0.0.0', port=5000, debug=True, use_reloader=True)