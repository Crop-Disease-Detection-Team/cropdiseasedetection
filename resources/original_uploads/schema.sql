-- ============================================================
-- Crop Disease Detection System — MySQL Database Schema
-- ============================================================
-- Run once:
--   mysql -u root -p < database/schema.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS crop_disease_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE crop_disease_db;

-- ----------------------------------------------------------------
-- users
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    id               INT UNSIGNED    NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name             VARCHAR(100)    NOT NULL,
    email            VARCHAR(150)    NOT NULL UNIQUE,
    password_hash    VARCHAR(255)    NOT NULL,
    phone            VARCHAR(20),
    address          TEXT,
    role             ENUM('user','admin') NOT NULL DEFAULT 'user',
    is_active        TINYINT(1)      NOT NULL DEFAULT 1,
    email_verified   TINYINT(1)      NOT NULL DEFAULT 0,
    verification_otp VARCHAR(6),
    otp_expires_at   DATETIME,
    otp_last_sent    DATETIME,
    profile_pic      VARCHAR(500),
    last_login       DATETIME,
    created_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role  (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------
-- diseases
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS diseases (
    id                    INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    disease_name          VARCHAR(150) NOT NULL UNIQUE,
    crop_type             VARCHAR(50),
    scientific_name       VARCHAR(200),
    description           TEXT,
    symptoms              TEXT,
    causes                TEXT,
    organic_treatment     TEXT,
    chemical_treatment    TEXT,
    prevention_tips       TEXT,
    recommended_medicines JSON,
    severity_level        ENUM('Low','Medium','High','Critical') DEFAULT 'Medium',
    typical_duration      VARCHAR(100),
    affected_crop_parts   VARCHAR(200),
    reference_image_url   VARCHAR(500),
    youtube_tutorial_url  VARCHAR(500),
    sample_image_url      VARCHAR(500),
    cultivation_regions   TEXT,
    created_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_crop_type   (crop_type),
    INDEX idx_disease_name(disease_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------
-- medicines
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS medicines (
    id                   INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    medicine_name        VARCHAR(150) NOT NULL UNIQUE,
    active_ingredient    VARCHAR(200),
    type                 ENUM('Fungicide','Insecticide','Bactericide','Herbicide','Organic'),
    application_method   ENUM('Spray','Drench','Dust','Seed Treatment'),
    dosage_per_liter     VARCHAR(100),
    waiting_period_days  INT,
    safety_precautions   TEXT,
    price_estimate       DECIMAL(10,2),
    manufacturer         VARCHAR(200),
    is_organic           TINYINT(1) DEFAULT 0,
    INDEX idx_type       (type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------
-- disease_medicine_mapping
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS disease_medicine_mapping (
    id                   INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    disease_id           INT UNSIGNED NOT NULL,
    medicine_id          INT UNSIGNED NOT NULL,
    effectiveness_rating TINYINT,
    usage_instructions   TEXT,
    UNIQUE KEY unique_mapping (disease_id, medicine_id),
    FOREIGN KEY (disease_id)  REFERENCES diseases(id)  ON DELETE CASCADE,
    FOREIGN KEY (medicine_id) REFERENCES medicines(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------
-- scan_history
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS scan_history (
    id             INT UNSIGNED  NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id        INT UNSIGNED  NOT NULL,
    image_path     VARCHAR(500),
    image_filename VARCHAR(255),
    disease_name   VARCHAR(150)  NOT NULL,
    confidence     DECIMAL(5,4)  NOT NULL,
    severity       VARCHAR(20),
    recommendation TEXT,
    scanned_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address     VARCHAR(45),
    device_info    TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id    (user_id),
    INDEX idx_scanned_at (scanned_at),
    INDEX idx_disease    (disease_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------
-- user_favorites
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_favorites (
    id         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id    INT UNSIGNED NOT NULL,
    disease_id INT UNSIGNED NOT NULL,
    notes      TEXT,
    saved_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_favorite (user_id, disease_id),
    FOREIGN KEY (user_id)    REFERENCES users(id)    ON DELETE CASCADE,
    FOREIGN KEY (disease_id) REFERENCES diseases(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------
-- feedback
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS feedback (
    id         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    user_id    INT UNSIGNED NOT NULL,
    message    TEXT         NOT NULL,
    status     VARCHAR(20)  NOT NULL DEFAULT 'pending',
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------
-- admin_logs (audit trail)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admin_logs (
    id          INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    admin_id    INT UNSIGNED NOT NULL,
    action      VARCHAR(100) NOT NULL,
    target_type VARCHAR(50),
    target_id   INT UNSIGNED,
    details     JSON,
    ip_address  VARCHAR(45),
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_admin_id   (admin_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------
-- system_settings
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS system_settings (
    id            INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    setting_key   VARCHAR(100) NOT NULL UNIQUE,
    setting_value TEXT,
    description   VARCHAR(255),
    updated_by    INT UNSIGNED,
    updated_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------
-- token_blacklist (logout / revocation)
-- ----------------------------------------------------------------
CREATE TABLE IF NOT EXISTS token_blacklist (
    id         INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
    jti        VARCHAR(36)  NOT NULL UNIQUE,
    created_at DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_jti (jti)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- ----------------------------------------------------------------
-- Default system settings
-- ----------------------------------------------------------------
INSERT IGNORE INTO system_settings (setting_key, setting_value, description)
VALUES
    ('app_name',              'Crop Disease Detection System', 'Application display name'),
    ('confidence_threshold',  '70',                           'Minimum confidence % to show result'),
    ('max_upload_size_mb',    '16',                           'Max image upload size in MB'),
    ('maintenance_mode',      'false',                        'Put app in read-only maintenance mode'),
    ('registration_open',     'true',                         'Allow new user registrations');
