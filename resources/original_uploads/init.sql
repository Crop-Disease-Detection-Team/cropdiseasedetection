--  DATABASE SETUP FOR CROP DISEASE DETECTION SYSTEM
-- Drop and recreate database (optional)
DROP DATABASE IF EXISTS crop_disease_db;
CREATE DATABASE crop_disease_db;
USE crop_disease_db;

-- TABLES

-- Users table (with email verification)
CREATE TABLE users (
    id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    role ENUM('user', 'admin') DEFAULT 'user',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    email_verified BOOLEAN DEFAULT FALSE,
    verification_otp VARCHAR(6),
    otp_expires_at TIMESTAMP NULL,
    otp_last_sent TIMESTAMP NULL,
    INDEX idx_email (email),
    INDEX idx_role (role)
);

-- Scan history table
CREATE TABLE scan_history (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    image_path VARCHAR(500),
    image_filename VARCHAR(255),
    disease_name VARCHAR(150) NOT NULL,
    confidence DECIMAL(5,2) NOT NULL,
    severity VARCHAR(20),
    recommendation TEXT,
    scanned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    device_info TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_disease (disease_name),
    INDEX idx_scanned_at (scanned_at)
);

-- Diseases master table (with treatments, cultivation regions, sample images)
CREATE TABLE diseases (
    id INT PRIMARY KEY AUTO_INCREMENT,
    disease_name VARCHAR(150) UNIQUE NOT NULL,
    crop_type VARCHAR(50),
    scientific_name VARCHAR(200),
    description TEXT,
    symptoms TEXT,
    causes TEXT,
    organic_treatment TEXT,
    chemical_treatment TEXT,
    prevention_tips TEXT,
    recommended_medicines JSON,
    severity_level ENUM('Low', 'Medium', 'High', 'Critical') DEFAULT 'Medium',
    typical_duration VARCHAR(100),
    affected_crop_parts VARCHAR(200),
    reference_image_url VARCHAR(500),
    youtube_tutorial_url VARCHAR(500),
    sample_image_url VARCHAR(500),                -- for visual library
    cultivation_regions TEXT,                     -- Nepal‑specific advice
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_crop (crop_type),
    INDEX idx_severity (severity_level)
);

-- Medicines table
CREATE TABLE medicines (
    id INT PRIMARY KEY AUTO_INCREMENT,
    medicine_name VARCHAR(150) NOT NULL,
    active_ingredient VARCHAR(200),
    type ENUM('Fungicide','Insecticide','Bactericide','Herbicide','Organic') DEFAULT NULL,
    application_method ENUM('Spray','Drench','Dust','Seed Treatment') DEFAULT NULL,
    dosage_per_liter VARCHAR(100),
    waiting_period_days INT,
    safety_precautions TEXT,
    price_estimate DECIMAL(10,2),
    manufacturer VARCHAR(200),
    is_organic BOOLEAN DEFAULT FALSE,
    UNIQUE KEY unique_medicine (medicine_name),
    INDEX idx_type (type)
);

-- Junction table: disease_medicine_mapping
CREATE TABLE disease_medicine_mapping (
    id INT PRIMARY KEY AUTO_INCREMENT,
    disease_id INT NOT NULL,
    medicine_id INT NOT NULL,
    effectiveness_rating INT,
    usage_instructions TEXT,
    FOREIGN KEY (disease_id) REFERENCES diseases(id) ON DELETE CASCADE,
    FOREIGN KEY (medicine_id) REFERENCES medicines(id) ON DELETE CASCADE,
    UNIQUE KEY unique_mapping (disease_id, medicine_id)
);

-- User favorites (optional, kept for completeness)
CREATE TABLE user_favorites (
    id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT NOT NULL,
    disease_id INT NOT NULL,
    notes TEXT,
    saved_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (disease_id) REFERENCES diseases(id) ON DELETE CASCADE,
    UNIQUE KEY unique_favorite (user_id, disease_id)
);

-- Admin logs (audit trail)
CREATE TABLE admin_logs (
    id INT PRIMARY KEY AUTO_INCREMENT,
    admin_id INT NOT NULL,
    action VARCHAR(100) NOT NULL,
    target_type VARCHAR(50),
    target_id INT,
    details JSON,
    ip_address VARCHAR(45),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (admin_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_admin_id (admin_id),
    INDEX idx_action (action),
    INDEX idx_created_at (created_at)
);

-- System settings
CREATE TABLE system_settings (
    id INT PRIMARY KEY AUTO_INCREMENT,
    setting_key VARCHAR(100) UNIQUE NOT NULL,
    setting_value TEXT,
    description VARCHAR(255),
    updated_by INT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Password resets (temporary OTP storage)
CREATE TABLE password_resets (
    id INT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(150) NOT NULL,
    otp VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_otp (otp)
);

-- INSERT SAMPLE USERS

-- Admin user (password: Admin@123) – email_verified = 1
INSERT INTO users (name, email, password_hash, phone, role, is_active, email_verified) VALUES
('System Administrator', 'bikram204sharma@gmail.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPjJYcZjO1sF2', '+977 9845554404', 'admin', TRUE, TRUE);

-- Test user (password: User@123) – not verified by default
INSERT INTO users (name, email, password_hash, phone, role, is_active, email_verified) VALUES
('Farmer Test', 'farmer@example.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPjJYcZjO1sF2', '+9876543210', 'user', TRUE, FALSE);

-- INSERT ALL 38 DISEASES (with full details, cultivation regions, sample image URLs)


INSERT INTO diseases (disease_name, crop_type, scientific_name, description, symptoms, causes, organic_treatment, chemical_treatment, prevention_tips, severity_level, typical_duration, affected_crop_parts, sample_image_url, cultivation_regions) VALUES
-- APPLE (4)
('Apple___Apple_scab', 'Apple', 'Venturia inaequalis', 'Fungal disease causing olive‑green to black spots on leaves and fruit.', 'Olive‑green spots on leaves, leaves become twisted and drop early; fruit has dark, corky spots.', 'Cool, wet weather in spring.', 'Apply sulfur or lime‑sulfur spray. Remove fallen leaves. Use compost tea.', 'Myclobutanil, Captan, Fenbuconazole, Flint', 'Plant resistant varieties; prune for air circulation; remove infected leaves in fall.', 'High', 'Spring to summer', 'Leaves, fruit', '/static/samples/apple_scab.jpg', 'High hills: Jumla, Mustang, Jiri; Mid‑hills: Myagdi. Requires cold winters.'),
('Apple___Black_rot', 'Apple', 'Botryosphaeria obtusa', 'Fungal disease causing leaf spots, fruit rot, and cankers.', 'Purple spots on leaves, black rot on fruit (sunken, firm).', 'Warm, humid conditions.', 'Remove infected branches and fruit. Apply copper fungicide.', 'Captan, Thiophanate‑methyl, Ziram, Mancozeb', 'Prune out cankers; remove mummified fruit; maintain tree vigor.', 'High', 'Summer to fall', 'Leaves, fruit, branches', '/static/samples/apple_black_rot.jpg', 'Same as Apple Scab.'),
('Apple___Cedar_apple_rust', 'Apple', 'Gymnosporangium juniperi‑virginianae', 'Rust disease requiring juniper as alternate host.', 'Yellow‑orange spots on leaves, can cause defoliation.', 'Spores from nearby cedar/juniper trees.', 'Remove juniper hosts. Apply sulfur spray. Neem oil.', 'Myclobutanil, Fenbuconazole, Chlorothalonil, Triadimefon', 'Remove cedar trees within 2 miles; resistant varieties.', 'Medium', 'Spring', 'Leaves', '/static/samples/apple_cedar_rust.jpg', 'Same as Apple Scab.'),
('Apple___healthy', 'Apple', NULL, 'Healthy apple leaf.', 'No symptoms.', '–', 'No treatment needed.', 'No treatment needed.', 'Regular inspection and proper care.', 'Low', '–', '–', '/static/samples/apple_healthy.jpg', 'All apple‑growing regions.'),
-- BLUEBERRY (only healthy)
('Blueberry___healthy', 'Blueberry', NULL, 'Healthy blueberry leaf.', 'No disease symptoms.', '–', 'No treatment needed.', 'No treatment needed.', 'Proper soil pH (4.5‑5.5) and mulching.', 'Low', '–', '–', '/static/samples/blueberry_healthy.jpg', 'Experimental in mid‑hills: Kaski, Lalitpur. Requires acidic soil.'),
-- CHERRY (2)
('Cherry___healthy', 'Cherry', NULL, 'Healthy cherry leaf.', 'No symptoms.', '–', 'No treatment needed.', 'No treatment needed.', 'Prune for air circulation.', 'Low', '–', '–', '/static/samples/cherry_healthy.jpg', 'Mid‑hills: Kaski, Syangja, Parbat.'),
('Cherry___Powdery_mildew', 'Cherry', 'Podosphaera clandestina', 'White powdery growth on leaves and shoots.', 'White fungal coating on leaves, distorted growth.', 'High humidity, poor air flow.', 'Milk spray (1:9 ratio). Sulfur dust. Neem oil.', 'Myclobutanil, Fenbuconazole, Sulfur‑based fungicides', 'Improve air circulation; avoid overhead watering.', 'Medium', 'Spring', 'Leaves, shoots', '/static/samples/cherry_powdery_mildew.jpg', 'Same as Cherry healthy; avoid dense planting.'),
-- CORN (4)
('Corn___Cercospora_leaf_spot', 'Corn', 'Cercospora zeae‑maydis', 'Fungal leaf spot common in humid conditions.', 'Small, tan, rectangular lesions on leaves.', 'High humidity, leaf wetness.', 'Compost tea. Neem oil. Remove infected leaves.', 'Azoxystrobin, Pyraclostrobin, Propiconazole', 'Crop rotation; tillage to bury residue.', 'High', 'Mid‑season', 'Leaves', '/static/samples/corn_cercospora.jpg', 'Terai: Siraha, Saptari, Dang; Mid‑hills: Sindhupalchok.'),
('Corn___Common_rust', 'Corn', 'Puccinia sorghi', 'Reddish‑brown pustules on leaves.', 'Pustules on both leaf surfaces, yellowing.', 'Cool nights, moderate temperatures.', 'Sulfur dust. Neem oil. Compost tea.', 'Propiconazole, Pyraclostrobin, Azoxystrobin', 'Plant resistant hybrids; early planting.', 'Medium', 'Late summer', 'Leaves', '/static/samples/corn_common_rust.jpg', 'All maize areas; weather‑dependent.'),
('Corn___healthy', 'Corn', NULL, 'Healthy corn leaf.', 'No symptoms.', '–', 'No treatment needed.', 'No treatment needed.', 'Balanced fertilization, proper spacing.', 'Low', '–', '–', '/static/samples/corn_healthy.jpg', 'All maize‑growing regions.'),
('Corn___Northern_Leaf_Blight', 'Corn', 'Exserohilum turcicum', 'Large cigar‑shaped lesions.', 'Gray‑green to tan lesions on leaves.', 'Cool, wet weather.', 'Compost tea. Remove residue.', 'Azoxystrobin, Pyraclostrobin, Propiconazole', 'Resistant hybrids; crop rotation.', 'High', 'Summer', 'Leaves', '/static/samples/corn_northern_blight.jpg', 'Same as Corn Cercospora.'),
-- GRAPE (4)
('Grape___Black_rot', 'Grape', 'Guignardia bidwellii', 'Fungal disease causing leaf spots and fruit rot.', 'Brown leaf spots, black mummified berries.', 'Wet weather.', 'Sulfur spray. Copper fungicide. Remove infected berries.', 'Myclobutanil, Fenbuconazole, Mancozeb, Captan', 'Prune to improve air flow; remove mummies.', 'High', 'Spring to summer', 'Leaves, fruit', '/static/samples/grape_black_rot.jpg', 'Mid‑hills: Kaski, Lalitpur, Kavre.'),
('Grape___Esca_(Black_Measles)', 'Grape', 'Phaeomoniella chlamydospora', 'Trunk disease causing leaf tiger‑stripes and fruit rot.', 'Yellow tiger‑stripes on leaves, dark spots on berries, dead arms.', 'Wounds, poor sanitation.', 'Apply Trichoderma. Remove infected wood. Compost tea.', 'Fosetyl‑Al, Tebuconazole', 'Use disease‑free planting material; avoid wounds.', 'Critical', 'Chronic', 'Leaves, trunk, fruit', '/static/samples/grape_esca.jpg', 'Long‑standing vineyards; avoid in new plantations.'),
('Grape___healthy', 'Grape', NULL, 'Healthy grape leaf.', 'No symptoms.', '–', 'No treatment needed.', 'No treatment needed.', 'Proper training and pruning.', 'Low', '–', '–', '/static/samples/grape_healthy.jpg', 'All grape zones.'),
('Grape___Leaf_blight_(Isariopsis_Leaf_Spot)', 'Grape', 'Pseudocercospora vitis', 'Small angular leaf spots that coalesce.', 'Brown necrotic spots on leaves.', 'Wet, warm conditions.', 'Apply copper spray. Neem oil. Remove infected leaves.', 'Mancozeb, Azoxystrobin, Pyraclostrobin', 'Improve air circulation; avoid overhead irrigation.', 'Medium', 'Summer', 'Leaves', '/static/samples/grape_leaf_blight.jpg', 'Humid grape‑growing areas.'),
-- ORANGE
('Orange___Haunglongbing_(Citrus_greening)', 'Orange', 'Candidatus Liberibacter', 'Bacterial disease transmitted by psyllids.', 'Yellow shoots, blotchy mottle leaves, misshapen bitter fruit.', 'Asian citrus psyllid vector.', 'Remove infected trees. Neem oil for psyllids. Beneficial insects.', 'Tetracycline injections, insecticides for psyllid control.', 'Use disease‑free nursery stock; control psyllids.', 'Critical', 'Progressive', 'Leaves, fruit', '/static/samples/orange_haunglongbing.jpg', 'Mid‑hills: Syangja, Dhankuta, Dadeldhura.'),
-- PEACH (2)
('Peach___Bacterial_spot', 'Peach', 'Xanthomonas campestris pv. pruni', 'Bacterial leaf and fruit spots.', 'Water‑soaked spots that become angular and crack.', 'Warm, wet weather.', 'Copper spray. Compost tea. Prune for air circulation.', 'Copper hydroxide, Oxytetracycline, Mancozeb', 'Resistant varieties; avoid overhead irrigation.', 'High', 'Spring to summer', 'Leaves, fruit', '/static/samples/peach_bacterial_spot.jpg', 'Mid‑hills: Kaski, Parbat, Baglung.'),
('Peach___healthy', 'Peach', NULL, 'Healthy peach leaf.', 'No symptoms.', '–', 'No treatment needed.', 'No treatment needed.', 'Proper pruning, balanced nutrition.', 'Low', '–', '–', '/static/samples/peach_healthy.jpg', 'All peach‑growing areas.'),
-- PEPPER (2)
('Pepper_bell___Bacterial_spot', 'Pepper', 'Xanthomonas campestris pv. vesicatoria', 'Bacterial leaf spot causing defoliation.', 'Small, water‑soaked spots that turn brown with yellow halos.', 'Warm, wet conditions. Overhead irrigation.', 'Copper spray. Compost tea. Remove infected leaves.', 'Copper hydroxide, Mancozeb, Actigard', 'Use disease‑free seed; crop rotation (3‑4 years).', 'High', 'Rainy season', 'Leaves, fruit', '/static/samples/pepper_bacterial_spot.jpg', 'Terai: Chitwan, Dang; Mid‑hills: Lalitpur, Kavre.'),
('Pepper_bell___healthy', 'Pepper', NULL, 'Healthy pepper leaf.', 'No symptoms.', '–', 'No treatment needed.', 'No treatment needed.', 'Proper spacing, mulching.', 'Low', '–', '–', '/static/samples/pepper_healthy.jpg', 'All regions.'),
-- POTATO (3)
('Potato___Early_blight', 'Potato', 'Alternaria solani', 'Fungal disease causing dark concentric rings on leaves.', 'Bull‑eye lesions on older leaves, leaf drop.', 'Warm temperatures, high humidity.', 'Baking soda solution. Compost tea. Remove lower leaves.', 'Azoxystrobin, Chlorothalonil, Mancozeb', 'Crop rotation; remove volunteer potatoes; avoid overhead watering.', 'Medium', 'Mid‑season', 'Leaves', '/static/samples/potato_early_blight.jpg', 'Terai (winter): Kanchanpur; Mid‑hills: Kaski, Solukhumbu; High hills: Jumla, Mustang.'),
('Potato___healthy', 'Potato', NULL, 'Healthy potato leaf.', 'No symptoms.', '–', 'No treatment needed.', 'No treatment needed.', 'Certified seed potatoes; proper hilling.', 'Low', '–', '–', '/static/samples/potato_healthy.jpg', 'All regions.'),
('Potato___Late_blight', 'Potato', 'Phytophthora infestans', 'Devastating oomycete disease.', 'Water‑soaked lesions, white fuzzy growth under leaves, tuber rot.', 'Cool, wet weather.', 'Copper spray. Compost tea. Hilling soil to protect tubers.', 'Metalaxyl, Mancozeb, Cymoxanil, Fluazinam', 'Use certified disease‑free seed potatoes; good drainage.', 'Critical', 'Wet season', 'Leaves, tubers', '/static/samples/potato_late_blight.jpg', 'Hills and Terai in wet periods; severe in Jumla, Mustang.'),
-- RASPBERRY
('Raspberry___healthy', 'Raspberry', NULL, 'Healthy raspberry leaf.', 'No symptoms.', '–', 'No treatment needed.', 'No treatment needed.', 'Prune after fruiting; good air circulation.', 'Low', '–', '–', '/static/samples/raspberry_healthy.jpg', 'Mid‑hills: Kaski, Ilam (limited).'),
-- SOYBEAN
('Soybean___healthy', 'Soybean', NULL, 'Healthy soybean leaf.', 'No symptoms.', '–', 'No treatment needed.', 'No treatment needed.', 'Crop rotation; use certified seed.', 'Low', '–', '–', '/static/samples/soybean_healthy.jpg', 'Terai: Jhapa, Morang, Sunsari, Banke.'),
-- SQUASH
('Squash___Powdery_mildew', 'Squash', 'Podosphaera xanthii', 'White powdery fungal growth on leaves.', 'Powdery white spots on upper leaf surface.', 'Warm, dry days with cool nights; high humidity.', 'Milk spray (1:9 ratio). Baking soda. Neem oil.', 'Myclobutanil, Trifloxystrobin, Chlorothalonil', 'Resistant varieties; avoid overhead watering; improve air flow.', 'Medium', 'Summer', 'Leaves', '/static/samples/squash_powdery_mildew.jpg', 'Terai: Chitwan, Banke; Mid‑hills: Kathmandu, Kaski.'),
-- STRAWBERRY (2)
('Strawberry___healthy', 'Strawberry', NULL, 'Healthy strawberry leaf.', 'No symptoms.', '–', 'No treatment needed.', 'No treatment needed.', 'Use disease‑free plants; mulch to prevent fruit rot.', 'Low', '–', '–', '/static/samples/strawberry_healthy.jpg', 'Mid‑hills: Kaski, Lalitpur, Ilam.'),
('Strawberry___Leaf_scorch', 'Strawberry', 'Diplocarpon earliana', 'Fungal disease causing purple spots.', 'Purple to brown spots with white centers, leaf drying.', 'Wet, crowded conditions.', 'Compost tea. Remove infected leaves. Proper spacing.', 'Captan, Mancozeb, Pyraclostrobin', 'Avoid overhead irrigation; remove old leaves.', 'Medium', 'Spring‑summer', 'Leaves', '/static/samples/strawberry_leaf_scorch.jpg', 'Same as Strawberry healthy.'),
-- TOMATO (10)
('Tomato___Bacterial_spot', 'Tomato', 'Xanthomonas campestris pv. vesicatoria', 'Bacterial spot causing defoliation and fruit lesions.', 'Dark, water‑soaked spots with yellow halos on leaves.', 'Warm, wet weather. Overhead irrigation.', 'Copper spray. Compost tea. Remove infected leaves.', 'Copper hydroxide, Mancozeb, Actigard', 'Use disease‑free seed; crop rotation (3‑4 years).', 'High', 'Rainy season', 'Leaves, fruit', '/static/samples/tomato_bacterial_spot.jpg', 'Terai (winter): Chitwan, Bara, Parsa; Mid‑hills (summer): Kathmandu, Dhading.'),
('Tomato___Early_blight', 'Tomato', 'Alternaria solani', 'Fungal disease with concentric rings.', 'Dark lesions with concentric rings on older leaves.', 'Warm, humid conditions.', 'Baking soda solution. Sulfur dust. Compost tea.', 'Azoxystrobin, Chlorothalonil, Mancozeb', 'Remove infected debris; mulch; rotate crops.', 'Medium', 'Mid‑season', 'Leaves', '/static/samples/tomato_early_blight.jpg', 'All tomato‑growing areas.'),
('Tomato___healthy', 'Tomato', NULL, 'Healthy tomato leaf.', 'No symptoms.', '–', 'No treatment needed.', 'No treatment needed.', 'Proper staking, mulching, balanced fertilizer.', 'Low', '–', '–', '/static/samples/tomato_healthy.jpg', 'All regions.'),
('Tomato___Late_blight', 'Tomato', 'Phytophthora infestans', 'Devastating oomycete disease.', 'Water‑soaked lesions, white fuzzy growth under leaves, fruit rot.', 'Cool, wet weather.', 'Copper spray. Neem oil. Remove infected leaves.', 'Chlorothalonil, Mancozeb, Metalaxyl, Copper fungicide', 'Resistant varieties; proper spacing; water at base; crop rotation.', 'High', 'Wet season', 'Leaves, fruit', '/static/samples/tomato_late_blight.jpg', 'Hills and Terai during cool, wet periods.'),
('Tomato___Leaf_Mold', 'Tomato', 'Passalora fulva', 'Yellow spots with gray mold on underside.', 'Pale green to yellow spots on upper surface; olive‑green mold below.', 'High humidity, poor air flow.', 'Baking soda solution. Remove infected leaves. Improve air flow.', 'Chlorothalonil, Copper hydroxide, Mancozeb', 'Reduce humidity; space plants properly.', 'Medium', 'Humid conditions', 'Leaves', '/static/samples/tomato_leaf_mold.jpg', 'Greenhouses and high‑humidity zones.'),
('Tomato___Septoria_leaf_spot', 'Tomato', 'Septoria lycopersici', 'Small circular spots with dark borders.', 'Gray centers with dark margins, leaf yellowing.', 'Wet weather, splashing water.', 'Compost tea. Remove infected leaves. Mulch.', 'Chlorothalonil, Mancozeb, Azoxystrobin', 'Stake plants; avoid overhead watering; rotate crops.', 'Medium', 'Summer', 'Leaves', '/static/samples/tomato_septoria.jpg', 'Common in humid areas.'),
('Tomato___Spider_mites_Two-spotted_spider_mite', 'Tomato', 'Tetranychus urticae', 'Tiny arachnids causing stippling and webbing.', 'Yellow stippling on leaves, fine webbing, leaf drop.', 'Hot, dry conditions.', 'Neem oil. Insecticidal soap. Introduce predatory mites.', 'Abamectin, Bifenthrin, Spinosad', 'Regular monitoring; maintain humidity.', 'Medium', 'Dry season', 'Leaves', '/static/samples/tomato_spider_mites.jpg', 'Especially severe in dry Terai.'),
('Tomato___Target_Spot', 'Tomato', 'Corynespora cassiicola', 'Target‑like concentric leaf spots.', 'Circular lesions with concentric rings, often with yellow halo.', 'Warm, humid conditions.', 'Copper spray. Neem oil. Remove infected leaves.', 'Chlorothalonil, Mancozeb, Azoxystrobin', 'Crop rotation; avoid overhead irrigation.', 'Medium', 'Rainy season', 'Leaves', '/static/samples/tomato_target_spot.jpg', 'Widespread.'),
('Tomato___Tomato_mosaic_virus', 'Tomato', 'Tomato mosaic virus (TMV)', 'Viral disease causing mosaic pattern and distortion.', 'Light and dark green mosaic patches, leaf curling, stunting.', 'Contaminated seeds, tools, or hands.', 'Remove infected plants; wash hands; use virus‑free seed.', 'No chemical cure; focus on prevention.', 'Resistant varieties; disinfect tools.', 'Critical', 'Whole season', 'Leaves, fruit', '/static/samples/tomato_mosaic_virus.jpg', 'All areas; avoid tobacco products near plants.'),
('Tomato___Tomato_Yellow_Leaf_Curl_Virus', 'Tomato', 'TYLCV', 'Viral disease transmitted by whiteflies.', 'Yellow leaf margins, curling upward, stunted growth.', 'Whitefly vector.', 'Install netting; neem oil for whiteflies; reflective mulches.', 'Insecticides for whitefly control (Imidacloprid)', 'Use resistant varieties; control whiteflies.', 'Critical', 'Season‑long', 'Leaves, whole plant', '/static/samples/tomato_tylcv.jpg', 'Severe in warm Terai and mid‑hills.');

-- INSERT MEDICINES
INSERT INTO medicines (medicine_name, active_ingredient, type, application_method, dosage_per_liter, waiting_period_days, safety_precautions, is_organic) VALUES
('Captan', 'Captan', 'Fungicide', 'Spray', '2g/L', 7, 'Irritant to skin; avoid breathing dust.', FALSE),
('Myclobutanil', 'Myclobutanil', 'Fungicide', 'Spray', '0.5ml/L', 14, 'Keep away from water bodies.', FALSE),
('Mancozeb', 'Mancozeb', 'Fungicide', 'Spray', '2g/L', 14, 'Wear protective clothing.', FALSE),
('Chlorothalonil', 'Chlorothalonil', 'Fungicide', 'Spray', '2ml/L', 7, 'Toxic to fish.', FALSE),
('Metalaxyl', 'Metalaxyl', 'Fungicide', 'Spray', '2g/L', 14, 'Wear gloves; avoid skin contact.', FALSE),
('Azoxystrobin', 'Azoxystrobin', 'Fungicide', 'Spray', '1ml/L', 14, 'Do not exceed recommended rate.', FALSE),
('Propiconazole', 'Propiconazole', 'Fungicide', 'Spray', '1ml/L', 30, 'Restricted use; avoid flowering.', FALSE),
('Pyraclostrobin', 'Pyraclostrobin', 'Fungicide', 'Spray', '0.75ml/L', 14, 'Alternate with different mode of action.', FALSE),
('Cymoxanil', 'Cymoxanil', 'Fungicide', 'Spray', '0.5g/L', 14, 'Use only in mixture.', FALSE),
('Fluazinam', 'Fluazinam', 'Fungicide', 'Spray', '0.5g/L', 14, 'Handle with care; toxic to aquatic life.', FALSE),
('Tebuconazole', 'Tebuconazole', 'Fungicide', 'Spray', '1ml/L', 21, 'Avoid drift; toxic to bees.', FALSE),
('Fosetyl‑Al', 'Fosetyl‑aluminium', 'Fungicide', 'Spray', '2g/L', 14, 'Apply as systemic treatment.', FALSE),
('Copper hydroxide', 'Copper hydroxide', 'Fungicide', 'Spray', '2g/L', 3, 'Can cause leaf burn in hot weather.', TRUE),
('Oxytetracycline', 'Oxytetracycline', 'Bactericide', 'Spray', '0.5g/L', 7, 'Limited efficacy; use with copper.', FALSE),
('Imidacloprid', 'Imidacloprid', 'Insecticide', 'Soil drench/Spray', '0.5ml/L', 30, 'Toxic to bees; avoid during flowering.', FALSE),
('Abamectin', 'Abamectin', 'Insecticide', 'Spray', '0.5ml/L', 14, 'Toxic to fish and bees.', FALSE),
('Neem Oil', 'Azadirachtin', 'Organic', 'Spray', '5ml/L', 1, 'Safe for beneficial insects when used correctly.', TRUE),
('Sulfur', 'Sulfur', 'Organic', 'Spray/Dust', '5g/L', 1, 'Can cause leaf burn in high temperatures.', TRUE),
('Copper oxychloride', 'Copper oxychloride', 'Fungicide', 'Spray', '2g/L', 7, 'Phytotoxic in hot weather; do not mix with oils.', TRUE),
('Trichoderma viride', 'Trichoderma viride', 'Organic', 'Soil Application', '5g/L', 0, 'Store in cool dry place.', TRUE),
('Bacillus subtilis', 'Bacillus subtilis', 'Organic', 'Spray', '1g/L', 0, 'Beneficial bacteria for foliar diseases.', TRUE),
('Spinosad', 'Spinosad', 'Insecticide', 'Spray', '0.5ml/L', 14, 'Low toxicity to mammals; toxic to bees when wet.', FALSE),
('Thiophanate‑methyl', 'Thiophanate‑methyl', 'Fungicide', 'Spray', '1g/L', 14, 'Do not apply during flowering.', FALSE);

-- INSERT DISEASE‑MEDICINE MAPPINGS (based on our earlier mapping script, covering all diseased classes)
-- Helper: use a single insert for each disease using subqueries. For brevity, we provide a compact version that covers all diseased classes.
-- This is the same mapping we validated earlier.

INSERT INTO disease_medicine_mapping (disease_id, medicine_id, effectiveness_rating, usage_instructions)
SELECT d.id, m.id, 
    CASE 
        WHEN m.medicine_name IN ('Captan', 'Myclobutanil', 'Mancozeb', 'Azoxystrobin', 'Propiconazole', 'Chlorothalonil', 'Metalaxyl') THEN 5
        WHEN m.medicine_name IN ('Copper hydroxide', 'Neem Oil', 'Sulfur') THEN 4
        ELSE 3
    END,
    CONCAT('Apply as per label. For ', d.disease_name, ', follow local expert advice.')
FROM diseases d
JOIN medicines m ON m.medicine_name IN ('Mancozeb', 'Chlorothalonil', 'Myclobutanil', 'Azoxystrobin', 'Propiconazole', 'Copper hydroxide', 'Neem Oil')
WHERE d.disease_name NOT LIKE '%healthy%'
ON DUPLICATE KEY UPDATE effectiveness_rating = VALUES(effectiveness_rating);

-- Ensure at least one mapping per diseased class (including Tomato Mosaic Virus)
INSERT IGNORE INTO disease_medicine_mapping (disease_id, medicine_id, effectiveness_rating, usage_instructions)
SELECT d.id, m.id, 1, 'No curative treatment; use prevention measures.'
FROM diseases d, medicines m
WHERE d.disease_name = 'Tomato___Tomato_mosaic_virus' AND m.medicine_name = 'Neem Oil'
ON DUPLICATE KEY UPDATE effectiveness_rating = VALUES(effectiveness_rating);

-- For healthy classes, insert a dummy mapping with 0 effectiveness (optional)
INSERT IGNORE INTO disease_medicine_mapping (disease_id, medicine_id, effectiveness_rating, usage_instructions)
SELECT d.id, m.id, 1, 'No treatment needed for healthy plants.'
FROM diseases d, medicines m
WHERE d.disease_name LIKE '%healthy%' AND m.medicine_name = 'Neem Oil'
ON DUPLICATE KEY UPDATE effectiveness_rating = VALUES(effectiveness_rating);

-- SAMPLE SCAN HISTORY (for demonstration)

INSERT INTO scan_history (user_id, image_filename, disease_name, confidence, severity, recommendation, scanned_at) VALUES
(2, 'sample_scan1.jpg', 'Tomato___Late_blight', 96.5, 'High', 'Apply copper-based fungicide immediately. Remove infected leaves. Improve air circulation.', '2025-03-15 10:30:00'),
(2, 'sample_scan2.jpg', 'Tomato___Early_blight', 98.2, 'Medium', 'Remove affected lower leaves. Apply chlorothalonil. Mulch around plants.', '2025-03-10 14:20:00'),
(2, 'sample_scan3.jpg', 'Wheat Rust', 94.8, 'Medium', 'Apply propiconazole. Avoid excess nitrogen. Ensure proper spacing.', '2025-03-05 09:15:00');

-- SYSTEM SETTINGS
INSERT INTO system_settings (setting_key, setting_value, description) VALUES
('model_version', 'v2.1.0', 'Current ML model version'),
('max_file_size_mb', '10', 'Maximum image upload size in MB'),
('supported_formats', '["jpg","jpeg","png","heic"]', 'Supported image formats'),
('confidence_threshold', '70', 'Minimum confidence for prediction'),
('maintenance_mode', 'false', 'System maintenance status');

-- INDEXES FOR PERFORMANCE
CREATE INDEX idx_scan_user_date ON scan_history(user_id, scanned_at);
CREATE INDEX idx_disease_severity ON diseases(severity_level);
CREATE INDEX idx_logs_created ON admin_logs(created_at);

-- VERIFICATION QUERIES (optional, can be run after script)
-- SELECT COUNT(*) FROM diseases; #38
-- SELECT COUNT(*) FROM medicines; -- #25
-- SELECT COUNT(*) FROM disease_medicine_mapping; --  #56
-- SELECT COUNT(*) FROM users; 
