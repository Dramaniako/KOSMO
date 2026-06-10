-- Schema for Kosmo Database

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS rooms;
DROP TABLE IF EXISTS properties;
DROP TABLE IF EXISTS users;

-- 1. Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    is_verified TINYINT(1) DEFAULT 0
);

-- 2. Create properties table
CREATE TABLE IF NOT EXISTS properties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    owner_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    price DECIMAL(12,2) NOT NULL,
    rating DECIMAL(2,1) DEFAULT 0.0,
    is_all_inclusive TINYINT(1) DEFAULT 1,
    all_inclusive_bills VARCHAR(500) DEFAULT NULL,
    image_url VARCHAR(500),
    latitude DOUBLE NOT NULL,
    longitude DOUBLE NOT NULL,
    total_rooms INT DEFAULT 10,
    occupied_rooms INT DEFAULT 0,
    description TEXT DEFAULT NULL,
    FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 2b. Create rooms table
CREATE TABLE IF NOT EXISTS rooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    property_id INT NOT NULL,
    room_number VARCHAR(100) NOT NULL,
    tenant_id INT DEFAULT NULL,
    description TEXT DEFAULT NULL,
    image_url VARCHAR(500) DEFAULT NULL,
    FOREIGN KEY (property_id) REFERENCES properties(id) ON DELETE CASCADE,
    FOREIGN KEY (tenant_id) REFERENCES users(id) ON DELETE SET NULL,
    UNIQUE KEY unique_property_room (property_id, room_number)
);

-- 3. Create transactions table
CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_number VARCHAR(100) NOT NULL UNIQUE,
    date_str VARCHAR(100) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    property_name VARCHAR(255) NOT NULL,
    user_id INT DEFAULT NULL,
    transaction_type VARCHAR(100) DEFAULT 'rental',
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 4. Seed initial users
TRUNCATE TABLE users;
INSERT INTO users (name, email, password_hash, is_verified) VALUES
('Budi Santoso', 'budi@email.com', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 1),
('Landlord Kosmo', 'landlord@email.com', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 1);

-- 5. Seed initial properties (Bali locations & coordinates)
TRUNCATE TABLE properties;
INSERT INTO properties (id, owner_id, title, location, address, price, rating, is_all_inclusive, all_inclusive_bills, image_url, latitude, longitude, total_rooms, occupied_rooms, description) VALUES
(1, 2, 'Kos Eksklusif Mawar', 'Badung', 'Jl. Sunset Road No. 45, Kuta, Badung, Bali', 2500000.0, 4.8, 1, 'Listrik,Air,WiFi', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400', -8.7225, 115.1825, 10, 0, 'Kos mewah dengan fasilitas lengkap di pusat kota Sunset Road. Dekat dengan mall, restoran, dan pantai Kuta. Dilengkapi AC, water heater, kasur springbed queen size, lemari pakaian, meja belajar, dan dapur pribadi.'),
(2, 2, 'Kos Mahasiswa Udayana', 'Badung', 'Jl. Kampus Unud, Jimbaran, Badung, Bali', 1500000.0, 4.5, 0, NULL, 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400', -8.7980, 115.1700, 15, 0, 'Kos khusus mahasiswa Udayana dengan harga sangat terjangkau. Lokasi strategis dekat dengan fakultas teknik dan kedokteran hewan. Fasilitas AC, kamar mandi dalam, kasur single, dan wifi berkecepatan tinggi.'),
(3, 2, 'Premium Residence Ubud', 'Gianyar', 'Jl. Raya Ubud No. 12, Ubud, Gianyar, Bali', 4500000.0, 4.9, 1, 'Air,WiFi,Kebersihan,Keamanan', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400', -8.5069, 115.2625, 12, 1, 'Premium residence di jantung keindahan alam Ubud. Kamar luas dengan pemandangan sawah yang asri. Suasana sangat tenang, cocok untuk remote worker. Fasilitas kolam renang bersama, AC, mini bar, dan hot tub.'),
(4, 2, 'KOSMO Hub Denpasar', 'Denpasar', 'Jl. Teuku Umar No. 14, Denpasar, Bali', 3500000.0, 4.7, 1, 'Listrik,Air,WiFi,Kebersihan,Keamanan,Parkir', 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=400', -8.6500, 115.2166, 5, 0, 'Modern co-living space di Denpasar dengan konsep smart home. Dilengkapi dengan communal area luas, rooftop area, cafe, gym kecil, dan coworking space untuk penghuni. Fasilitas smart lock, AC, smart TV.');

-- 5b. Seed initial rooms
TRUNCATE TABLE rooms;
INSERT INTO rooms (property_id, room_number, tenant_id, description, image_url) VALUES
(1, 'Kamar 101', NULL, 'Kamar standar dengan ventilasi udara segar.', 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=400'),
(1, 'Kamar 102', NULL, 'Kamar standar menghadap ke taman.', 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=400'),
(1, 'Kamar 103', NULL, 'Kamar standar dekat dengan area parkir.', 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=400'),
(2, 'Kamar A', NULL, 'Kamar mahasiswa ekonomis dengan kamar mandi dalam.', 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&q=80&w=400'),
(2, 'Kamar B', NULL, 'Kamar mahasiswa ekonomis dekat area jemuran.', 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&q=80&w=400'),
(3, 'Kamar 2A', 1, 'Kamar premium dengan pemandangan sawah langsung.', 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&q=80&w=400'),
(3, 'Kamar 2B', NULL, 'Kamar premium dekat area kolam renang.', 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&q=80&w=400'),
(3, 'Kamar 2C', NULL, 'Kamar premium lantai dua dengan balkon luas.', 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&q=80&w=400'),
(4, 'Room 1', NULL, 'Co-living room dengan fasilitas smart lock.', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400'),
(4, 'Room 2', NULL, 'Co-living room dengan pencahayaan alami yang baik.', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400');

-- 6. Seed initial transactions
TRUNCATE TABLE transactions;
INSERT INTO transactions (invoice_number, date_str, amount, status, property_name, user_id, transaction_type) VALUES
('INV-KSM-0526-001', '5 Mei 2026', 4500000.0, 'failed', 'Premium Residence Ubud (Kamar 2A)', 1, 'arrears'),
('INV-KSM-0426-001', '5 Apr 2026', 4500000.0, 'success', 'Premium Residence Ubud (Kamar 2A)', 1, 'monthly'),
('INV-KSM-0326-001', '5 Mar 2026', 4550000.0, 'success', 'Premium Residence Ubud (Kamar 2A)', 1, 'rental');

SET FOREIGN_KEY_CHECKS = 1;

-- 7. Create withdrawals table
DROP TABLE IF EXISTS withdrawals;
CREATE TABLE IF NOT EXISTS withdrawals (
    id INT AUTO_INCREMENT PRIMARY KEY,
    landlord_id INT NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    bank_name VARCHAR(100) NOT NULL,
    account_number VARCHAR(100) NOT NULL,
    date_str VARCHAR(100) NOT NULL,
    status VARCHAR(50) NOT NULL,
    FOREIGN KEY (landlord_id) REFERENCES users(id) ON DELETE CASCADE
);

