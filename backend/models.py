"""
db_models.py
=============
All SQLAlchemy ORM models for the Crop Disease Detection System.

NOTE: Named `db_models.py` (not `models.py`) to avoid collision with
the `models/` directory that stores ML weight files
(best_model.pth, class_names.json).
"""
from datetime import datetime

from flask_bcrypt import Bcrypt
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()
bcrypt = Bcrypt()


# ---------------------------------------------------------------------------
# User
# ---------------------------------------------------------------------------

class User(db.Model):
    __tablename__ = "users"

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(150), unique=True, nullable=False, index=True)
    password_hash = db.Column(db.String(255), nullable=False)
    phone = db.Column(db.String(20))
    address = db.Column(db.Text)
    role = db.Column(db.Enum("user", "admin"), default="user", nullable=False)
    is_active = db.Column(db.Boolean, default=True, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_login = db.Column(db.DateTime)
    

    # Email verification
    email_verified = db.Column(db.Boolean, default=False, nullable=False)
    verification_otp = db.Column(db.String(6))
    otp_expires_at = db.Column(db.DateTime)
    otp_last_sent = db.Column(db.DateTime)

    profile_pic = db.Column(db.String(500))

    # Relationships
    scans = db.relationship("ScanHistory", backref="user", lazy=True, cascade="all, delete-orphan")
    favorites = db.relationship("UserFavorite", backref="user", lazy=True, cascade="all, delete-orphan")
    feedbacks = db.relationship("Feedback", backref="user", lazy=True, cascade="all, delete-orphan")
    admin_logs = db.relationship("AdminLog", backref="admin", lazy=True, foreign_keys="AdminLog.admin_id")

    # -- Password helpers -------------------------------------------------
    def set_password(self, raw_password: str) -> None:
        self.password_hash = bcrypt.generate_password_hash(raw_password).decode("utf-8")

    def check_password(self, raw_password: str) -> bool:
        return bcrypt.check_password_hash(self.password_hash, raw_password)

    # -- Serialization ------------------------------------------------------
    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "email": self.email,
            "phone": self.phone,
            "address": self.address,
            "role": self.role,
            "is_active": self.is_active,
            "email_verified": self.email_verified,
            "profile_pic": self.profile_pic,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "last_login": self.last_login.isoformat() if self.last_login else None,
        }


# ---------------------------------------------------------------------------
# Scan History
# ---------------------------------------------------------------------------

class ScanHistory(db.Model):
    __tablename__ = "scan_history"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    image_path = db.Column(db.String(500))
    image_filename = db.Column(db.String(255))
    disease_name = db.Column(db.String(150), nullable=False, index=True)
    confidence = db.Column(db.Numeric(5, 2), nullable=False)
    severity = db.Column(db.String(20))
    recommendation = db.Column(db.Text)
    scanned_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    ip_address = db.Column(db.String(45))
    device_info = db.Column(db.Text)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "disease_name": self.disease_name,
            "confidence": float(self.confidence),
            "severity": self.severity,
            "recommendation": self.recommendation,
            "scanned_at": self.scanned_at.isoformat() if self.scanned_at else None,
            "image_url": self.image_path,
        }


# ---------------------------------------------------------------------------
# Disease
# ---------------------------------------------------------------------------

class Disease(db.Model):
    __tablename__ = "diseases"

    id = db.Column(db.Integer, primary_key=True)
    disease_name = db.Column(db.String(150), unique=True, nullable=False, index=True)
    crop_type = db.Column(db.String(50))
    scientific_name = db.Column(db.String(200))
    description = db.Column(db.Text)
    symptoms = db.Column(db.Text)
    causes = db.Column(db.Text)
    organic_treatment = db.Column(db.Text)
    chemical_treatment = db.Column(db.Text)
    prevention_tips = db.Column(db.Text)
    recommended_medicines = db.Column(db.JSON)
    severity_level = db.Column(db.Enum("Low", "Medium", "High", "Critical"), default="Medium")
    typical_duration = db.Column(db.String(100))
    affected_crop_parts = db.Column(db.String(200))
    reference_image_url = db.Column(db.String(500))
    youtube_tutorial_url = db.Column(db.String(500))
    sample_image_url = db.Column(db.String(500))
    cultivation_regions = db.Column(db.Text)

    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    medicine_mappings = db.relationship(
        "DiseaseMedicineMapping", backref="disease", lazy=True, cascade="all, delete-orphan"
    )
    favorites = db.relationship("UserFavorite", backref="disease", lazy=True)

    def to_dict(self, include_medicines: bool = True) -> dict:
        severity = self.severity_level
        severity = severity.value if hasattr(severity, "value") else severity

        data = {
            "id": self.id,
            "disease_name": self.disease_name,
            "crop_type": self.crop_type,
            "scientific_name": self.scientific_name,
            "description": self.description,
            "symptoms": self.symptoms,
            "causes": self.causes,
            "organic_treatment": self.organic_treatment,
            "chemical_treatment": self.chemical_treatment,
            "prevention_tips": self.prevention_tips,
            "severity_level": severity,
            "typical_duration": self.typical_duration,
            "affected_crop_parts": self.affected_crop_parts,
            "youtube_tutorial_url": self.youtube_tutorial_url,
            "reference_image_url": self.reference_image_url,
            "recommended_medicines": self.recommended_medicines or [],
            "sample_image_url": self.sample_image_url,
            "cultivation_regions": self.cultivation_regions,
        }
        if include_medicines:
            data["medicines"] = [m.medicine.to_dict() for m in self.medicine_mappings if m.medicine]
        return data


# ---------------------------------------------------------------------------
# Medicine
# ---------------------------------------------------------------------------

class Medicine(db.Model):
    __tablename__ = "medicines"

    id = db.Column(db.Integer, primary_key=True)
    medicine_name = db.Column(db.String(150), unique=True, nullable=False)
    active_ingredient = db.Column(db.String(200))
    type = db.Column(db.Enum("Fungicide", "Insecticide", "Bactericide", "Herbicide", "Organic"))
    application_method = db.Column(db.Enum("Spray", "Drench", "Dust", "Seed Treatment"))
    dosage_per_liter = db.Column(db.String(100))
    waiting_period_days = db.Column(db.Integer)
    safety_precautions = db.Column(db.Text)
    price_estimate = db.Column(db.Numeric(10, 2))
    manufacturer = db.Column(db.String(200))
    is_organic = db.Column(db.Boolean, default=False)

    disease_mappings = db.relationship("DiseaseMedicineMapping", backref="medicine", lazy=True)

    def to_dict(self) -> dict:
        med_type = self.type.value if hasattr(self.type, "value") else self.type
        app_method = self.application_method.value if hasattr(self.application_method, "value") else self.application_method
        return {
            "id": self.id,
            "medicine_name": self.medicine_name,
            "active_ingredient": self.active_ingredient,
            "type": med_type,
            "application_method": app_method,
            "dosage_per_liter": self.dosage_per_liter,
            "waiting_period_days": self.waiting_period_days,
            "safety_precautions": self.safety_precautions,
            "price_estimate": float(self.price_estimate) if self.price_estimate else None,
            "manufacturer": self.manufacturer,
            "is_organic": self.is_organic,
        }


# ---------------------------------------------------------------------------
# Disease <-> Medicine mapping
# ---------------------------------------------------------------------------

class DiseaseMedicineMapping(db.Model):
    __tablename__ = "disease_medicine_mapping"

    id = db.Column(db.Integer, primary_key=True)
    disease_id = db.Column(db.Integer, db.ForeignKey("diseases.id"), nullable=False)
    medicine_id = db.Column(db.Integer, db.ForeignKey("medicines.id"), nullable=False)
    effectiveness_rating = db.Column(db.Integer)
    usage_instructions = db.Column(db.Text)

    __table_args__ = (db.UniqueConstraint("disease_id", "medicine_id", name="unique_mapping"),)


# ---------------------------------------------------------------------------
# User Favorites
# ---------------------------------------------------------------------------

class UserFavorite(db.Model):
    __tablename__ = "user_favorites"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    disease_id = db.Column(db.Integer, db.ForeignKey("diseases.id"), nullable=False)
    notes = db.Column(db.Text)
    saved_at = db.Column(db.DateTime, default=datetime.utcnow)

    __table_args__ = (db.UniqueConstraint("user_id", "disease_id", name="unique_favorite"),)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "disease": self.disease.to_dict(include_medicines=False) if self.disease else None,
            "notes": self.notes,
            "saved_at": self.saved_at.isoformat() if self.saved_at else None,
        }


# ---------------------------------------------------------------------------
# Admin Logs (audit trail)
# ---------------------------------------------------------------------------

class AdminLog(db.Model):
    __tablename__ = "admin_logs"

    id = db.Column(db.Integer, primary_key=True)
    admin_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    action = db.Column(db.String(100), nullable=False)
    target_type = db.Column(db.String(50))
    target_id = db.Column(db.Integer)
    details = db.Column(db.JSON)
    ip_address = db.Column(db.String(45))
    created_at = db.Column(db.DateTime, default=datetime.utcnow, index=True)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "admin_name": self.admin.name if self.admin else "Unknown",
            "action": self.action,
            "target_type": self.target_type,
            "target_id": self.target_id,
            "details": self.details,
            "ip_address": self.ip_address,
            "created_at": self.created_at.isoformat() if self.created_at else None,
        }


# ---------------------------------------------------------------------------
# System Settings
# ---------------------------------------------------------------------------

class SystemSetting(db.Model):
    __tablename__ = "system_settings"

    id = db.Column(db.Integer, primary_key=True)
    setting_key = db.Column(db.String(100), unique=True, nullable=False)
    setting_value = db.Column(db.Text)
    description = db.Column(db.String(255))
    updated_by = db.Column(db.Integer, db.ForeignKey("users.id"))
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self) -> dict:
        return {"key": self.setting_key, "value": self.setting_value, "description": self.description}


# ---------------------------------------------------------------------------
# Token Blacklist (logout support)
# ---------------------------------------------------------------------------

class TokenBlacklist(db.Model):
    __tablename__ = "token_blacklist"

    id = db.Column(db.Integer, primary_key=True)
    jti = db.Column(db.String(36), nullable=False, unique=True, index=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    def __repr__(self) -> str:
        return f"<TokenBlacklist {self.jti}>"


# ---------------------------------------------------------------------------
# Feedback
# ---------------------------------------------------------------------------

class Feedback(db.Model):
    __tablename__ = "feedback"

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False)
    message = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(20), default="pending")  # pending | read | resolved
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "user_name": self.user.name if self.user else None,
            "user_email": self.user.email if self.user else None,
            "message": self.message,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
