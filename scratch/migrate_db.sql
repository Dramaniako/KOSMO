-- 1. Drop triggers if they exist
DROP TRIGGER IF EXISTS before_insert_users;
DROP TRIGGER IF EXISTS before_insert_properties;
DROP TRIGGER IF EXISTS before_update_properties;
DROP TRIGGER IF EXISTS before_insert_withdrawals;
DROP TRIGGER IF EXISTS before_update_withdrawals;
DROP TRIGGER IF EXISTS before_insert_reviews;
DROP TRIGGER IF EXISTS before_update_reviews;

-- 2. Create trigger before_insert_users
CREATE TRIGGER before_insert_users
BEFORE INSERT ON users
FOR EACH ROW
BEGIN
    IF NEW.id IS NULL OR NEW.id = '' THEN
        SET NEW.id = CONCAT('usr-', UUID());
    END IF;
END;

-- 3. Create triggers for properties
CREATE TRIGGER before_insert_properties
BEFORE INSERT ON properties
FOR EACH ROW
BEGIN
    IF NEW.id IS NULL OR NEW.id = '' THEN
        SET NEW.id = CONCAT('prop-', UUID());
    END IF;
    IF NEW.ownerId IS NULL OR NEW.ownerId = '' THEN
        SET NEW.ownerId = (SELECT id FROM users WHERE id_int = NEW.owner_id_int);
    END IF;
    IF NEW.owner_id_int IS NULL THEN
        SET NEW.owner_id_int = (SELECT id_int FROM users WHERE id = NEW.ownerId);
    END IF;
END;

CREATE TRIGGER before_update_properties
BEFORE UPDATE ON properties
FOR EACH ROW
BEGIN
    IF NEW.ownerId <> OLD.ownerId OR (NEW.ownerId IS NOT NULL AND OLD.ownerId IS NULL) THEN
        SET NEW.owner_id_int = (SELECT id_int FROM users WHERE id = NEW.ownerId);
    END IF;
    IF NEW.owner_id_int <> OLD.owner_id_int OR (NEW.owner_id_int IS NOT NULL AND OLD.owner_id_int IS NULL) THEN
        SET NEW.ownerId = (SELECT id FROM users WHERE id_int = NEW.owner_id_int);
    END IF;
END;

-- 4. Create triggers for withdrawals
CREATE TRIGGER before_insert_withdrawals
BEFORE INSERT ON withdrawals
FOR EACH ROW
BEGIN
    IF NEW.id IS NULL OR NEW.id = '' THEN
        SET NEW.id = CONCAT('w-', UUID());
    END IF;
    IF NEW.userId IS NULL OR NEW.userId = '' THEN
        SET NEW.userId = (SELECT id FROM users WHERE id_int = NEW.landlord_id_int);
    END IF;
    IF NEW.landlord_id_int IS NULL THEN
        SET NEW.landlord_id_int = (SELECT id_int FROM users WHERE id = NEW.userId);
    END IF;
END;

CREATE TRIGGER before_update_withdrawals
BEFORE UPDATE ON withdrawals
FOR EACH ROW
BEGIN
    IF NEW.userId <> OLD.userId OR (NEW.userId IS NOT NULL AND OLD.userId IS NULL) THEN
        SET NEW.landlord_id_int = (SELECT id_int FROM users WHERE id = NEW.userId);
    END IF;
    IF NEW.landlord_id_int <> OLD.landlord_id_int OR (NEW.landlord_id_int IS NOT NULL AND OLD.landlord_id_int IS NULL) THEN
        SET NEW.userId = (SELECT id FROM users WHERE id_int = NEW.landlord_id_int);
    END IF;
END;

-- 5. Create triggers for reviews (auto-populates propertyName and userName if null)
CREATE TRIGGER before_insert_reviews
BEFORE INSERT ON reviews
FOR EACH ROW
BEGIN
    IF NEW.id IS NULL OR NEW.id = '' THEN
        SET NEW.id = CONCAT('rev-', UUID());
    END IF;
    
    -- Sync property ID
    IF NEW.property_id_int IS NOT NULL AND (NEW.propertyId IS NULL OR NEW.propertyId = '') THEN
        SET NEW.propertyId = (SELECT id FROM properties WHERE id_int = NEW.property_id_int);
    END IF;
    IF NEW.propertyId IS NOT NULL AND NEW.property_id_int IS NULL THEN
        SET NEW.property_id_int = (SELECT id_int FROM properties WHERE id = NEW.propertyId);
    END IF;
    
    -- Auto-fill propertyName
    IF NEW.propertyName IS NULL OR NEW.propertyName = '' THEN
        SET NEW.propertyName = (SELECT name FROM properties WHERE id_int = NEW.property_id_int);
    END IF;

    -- Sync user ID
    IF NEW.user_id_int IS NOT NULL AND (NEW.userId IS NULL OR NEW.userId = '') THEN
        SET NEW.userId = (SELECT id FROM users WHERE id_int = NEW.user_id_int);
    END IF;
    IF NEW.userId IS NOT NULL AND NEW.user_id_int IS NULL THEN
        SET NEW.user_id_int = (SELECT id_int FROM users WHERE id = NEW.userId);
    END IF;
    
    -- Auto-fill userName
    IF NEW.userName IS NULL OR NEW.userName = '' THEN
        SET NEW.userName = (SELECT name FROM users WHERE id_int = NEW.user_id_int);
    END IF;
END;

CREATE TRIGGER before_update_reviews
BEFORE UPDATE ON reviews
FOR EACH ROW
BEGIN
    IF NEW.propertyId <> OLD.propertyId OR (NEW.propertyId IS NOT NULL AND OLD.propertyId IS NULL) THEN
        SET NEW.property_id_int = (SELECT id_int FROM properties WHERE id = NEW.propertyId);
    END IF;
    IF NEW.userId <> OLD.userId OR (NEW.userId IS NOT NULL AND OLD.userId IS NULL) THEN
        SET NEW.user_id_int = (SELECT id_int FROM users WHERE id = NEW.userId);
    END IF;
    IF NEW.property_id_int <> OLD.property_id_int OR (NEW.property_id_int IS NOT NULL AND OLD.property_id_int IS NULL) THEN
        SET NEW.propertyId = (SELECT id FROM properties WHERE id_int = NEW.property_id_int);
    END IF;
    IF NEW.user_id_int <> OLD.user_id_int OR (NEW.user_id_int IS NOT NULL AND OLD.user_id_int IS NULL) THEN
        SET NEW.userId = (SELECT id FROM users WHERE id_int = NEW.user_id_int);
    END IF;
END;

-- 6. Backfill mappings for existing records
UPDATE users SET is_verified = 1 WHERE email IN ('admin@kosmo.com', 'landlord@kosmo.com', 'tenant@kosmo.com');

UPDATE properties p 
JOIN users u ON p.ownerId = u.id 
SET p.owner_id_int = u.id_int;

UPDATE withdrawals w 
JOIN users u ON w.userId = u.id 
SET w.landlord_id_int = u.id_int;

UPDATE reviews r 
JOIN properties p ON r.propertyId = p.id 
JOIN users u ON r.userId = u.id 
SET r.property_id_int = p.id_int, r.user_id_int = u.id_int;

-- 7. Seed mobile test users if they do not exist
INSERT INTO users (id, name, email, password, role, phone, is_verified, age, gender, address)
SELECT 'user-budi', 'Budi Santoso', 'budi@email.com', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'tenant', '+62811111111', 1, 22, 'Laki-laki', 'Jl. Hayam Wuruk No. 5, Denpasar'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'budi@email.com');

INSERT INTO users (id, name, email, password, role, phone, is_verified, age, gender, address)
SELECT 'user-landlord-kosmo', 'Landlord Kosmo', 'landlord@email.com', 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f', 'landlord', '+628123456789', 1, 45, 'Laki-laki', 'Jl. Sunset Road No. 10, Badung, Bali'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'landlord@email.com');

-- 8. Seed mobile-only properties if they do not exist (including default price = 0)
INSERT INTO properties (id, ownerId, name, district, address, rating, image, latitude, longitude, totalRooms, occupiedRooms, description, price)
SELECT 'prop-mawar', (SELECT id FROM users WHERE email = 'landlord@email.com'), 'Kos Eksklusif Mawar', 'Badung', 'Jl. Sunset Road No. 45, Kuta, Badung, Bali', 4.8, 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400', -8.7225, 115.1825, 3, 0, 'Kos mewah dengan fasilitas lengkap di pusat kota Sunset Road. Dekat dengan mall, restoran, dan pantai Kuta. Dilengkapi AC, water heater, kasur springbed queen size, lemari pakaian, meja belajar, dan dapur pribadi.', 2500000
WHERE NOT EXISTS (SELECT 1 FROM properties WHERE name = 'Kos Eksklusif Mawar');

INSERT INTO properties (id, ownerId, name, district, address, rating, image, latitude, longitude, totalRooms, occupiedRooms, description, price)
SELECT 'prop-udayana', (SELECT id FROM users WHERE email = 'landlord@email.com'), 'Kos Mahasiswa Udayana', 'Badung', 'Jl. Kampus Unud, Jimbaran, Badung, Bali', 4.5, 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400', -8.7980, 115.1700, 2, 0, 'Kos khusus mahasiswa Udayana dengan harga sangat terjangkau. Lokasi strategis dekat dengan fakultas teknik dan kedokteran hewan. Fasilitas AC, kamar mandi dalam, kasur single, dan wifi berkecepatan tinggi.', 1500000
WHERE NOT EXISTS (SELECT 1 FROM properties WHERE name = 'Kos Mahasiswa Udayana');

INSERT INTO properties (id, ownerId, name, district, address, rating, image, latitude, longitude, totalRooms, occupiedRooms, description, price)
SELECT 'prop-ubud-mobile', (SELECT id FROM users WHERE email = 'landlord@email.com'), 'Premium Residence Ubud', 'Gianyar', 'Jl. Raya Ubud No. 12, Ubud, Gianyar, Bali', 4.9, 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400', -8.5069, 115.2625, 3, 1, 'Premium residence di jantung keindahan alam Ubud. Kamar luas dengan pemandangan sawah yang asri. Suasana sangat tenang, cocok untuk remote worker. Fasilitas kolam renang bersama, AC, mini bar, dan hot tub.', 4500000
WHERE NOT EXISTS (SELECT 1 FROM properties WHERE name = 'Premium Residence Ubud');

-- Refresh owners sync after inserts
UPDATE properties p 
JOIN users u ON p.ownerId = u.id 
SET p.owner_id_int = u.id_int
WHERE p.owner_id_int IS NULL;

-- 9. Create mobile-only tables
CREATE TABLE IF NOT EXISTS rooms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    property_id INT NOT NULL,
    room_number VARCHAR(100) NOT NULL,
    tenant_id INT DEFAULT NULL,
    description TEXT DEFAULT NULL,
    image_url VARCHAR(500) DEFAULT NULL,
    price DECIMAL(12,2) NOT NULL DEFAULT 0.0,
    is_all_inclusive TINYINT(1) DEFAULT 1,
    all_inclusive_bills VARCHAR(500) DEFAULT NULL,
    UNIQUE KEY unique_property_room (property_id, room_number)
);

CREATE TABLE IF NOT EXISTS transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_number VARCHAR(100) NOT NULL UNIQUE,
    date_str VARCHAR(100) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    status VARCHAR(50) NOT NULL,
    property_name VARCHAR(255) NOT NULL,
    user_id INT DEFAULT NULL,
    transaction_type VARCHAR(100) DEFAULT 'rental',
    property_id INT DEFAULT NULL,
    room_id INT DEFAULT NULL
);

CREATE TABLE IF NOT EXISTS reviews_tenants (
    id INT AUTO_INCREMENT PRIMARY KEY,
    landlord_id INT NOT NULL,
    tenant_id INT NOT NULL,
    rating DECIMAL(2,1) NOT NULL,
    comment TEXT DEFAULT NULL,
    date_str VARCHAR(100) NOT NULL
);

-- 10. Seed rooms
INSERT IGNORE INTO rooms (property_id, room_number, tenant_id, description, image_url, price, is_all_inclusive, all_inclusive_bills) VALUES
((SELECT id_int FROM properties WHERE name = 'Kos Eksklusif Mawar'), 'Kamar 101', NULL, 'Kamar standar dengan ventilasi udara segar.', 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=400', 2500000.0, 1, 'Listrik,Air,WiFi'),
((SELECT id_int FROM properties WHERE name = 'Kos Eksklusif Mawar'), 'Kamar 102', NULL, 'Kamar deluxe dengan balkon luas.', 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=400', 2800000.0, 1, 'Listrik,Air,WiFi,Kebersihan'),
((SELECT id_int FROM properties WHERE name = 'Kos Eksklusif Mawar'), 'Kamar 103', NULL, 'Kamar standar dekat dengan area parkir.', 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=400', 2500000.0, 1, 'Listrik,Air,WiFi');

INSERT IGNORE INTO rooms (property_id, room_number, tenant_id, description, image_url, price, is_all_inclusive, all_inclusive_bills) VALUES
((SELECT id_int FROM properties WHERE name = 'Kos Mahasiswa Udayana'), 'Kamar A', NULL, 'Kamar mahasiswa ekonomis dengan kamar mandi dalam.', 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&q=80&w=400', 1500000.0, 0, NULL),
((SELECT id_int FROM properties WHERE name = 'Kos Mahasiswa Udayana'), 'Kamar B', NULL, 'Kamar mahasiswa ekonomis dekat area jemuran.', 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&q=80&w=400', 1500000.0, 0, NULL);

INSERT IGNORE INTO rooms (property_id, room_number, tenant_id, description, image_url, price, is_all_inclusive, all_inclusive_bills) VALUES
((SELECT id_int FROM properties WHERE name = 'Premium Residence Ubud'), 'Kamar 2A', (SELECT id_int FROM users WHERE email = 'budi@email.com'), 'Kamar premium dengan pemandangan sawah langsung.', 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&q=80&w=400', 4500000.0, 1, 'Air,WiFi,Kebersihan,Keamanan'),
((SELECT id_int FROM properties WHERE name = 'Premium Residence Ubud'), 'Kamar 2B', NULL, 'Kamar premium dekat area kolam renang.', 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&q=80&w=400', 4500000.0, 1, 'Air,WiFi,Kebersihan,Keamanan'),
((SELECT id_int FROM properties WHERE name = 'Premium Residence Ubud'), 'Kamar 2C', NULL, 'Kamar premium lantai dua dengan balkon luas.', 'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&q=80&w=400', 4500000.0, 1, 'Air,WiFi,Kebersihan,Keamanan');

INSERT IGNORE INTO rooms (property_id, room_number, tenant_id, description, image_url, price, is_all_inclusive, all_inclusive_bills) VALUES
((SELECT id_int FROM properties WHERE id = 'prop-01'), 'Room 1', NULL, 'Co-living room dengan fasilitas smart lock.', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400', 3500000.0, 1, 'Listrik,Air,WiFi,Kebersihan,Keamanan,Parkir'),
((SELECT id_int FROM properties WHERE id = 'prop-01'), 'Room 2', NULL, 'Co-living room dengan pencahayaan alami yang baik.', 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?auto=format&fit=crop&q=80&w=400', 3500000.0, 1, 'Listrik,Air,WiFi,Kebersihan,Keamanan,Parkir');

INSERT IGNORE INTO rooms (property_id, room_number, tenant_id, description, image_url, price, is_all_inclusive, all_inclusive_bills) VALUES
((SELECT id_int FROM properties WHERE id = 'prop-02'), 'Room S1', NULL, 'Premium seminyak room.', 'https://images.unsplash.com/photo-1502672260266-1c1de2d96674?auto=format&fit=crop&q=80&w=400', 4500000.0, 1, 'Listrik,Air,WiFi,Kebersihan,Keamanan,Parkir');

INSERT IGNORE INTO rooms (property_id, room_number, tenant_id, description, image_url, price, is_all_inclusive, all_inclusive_bills) VALUES
((SELECT id_int FROM properties WHERE id = 'prop-03'), 'Room U1', NULL, 'Ubud village style room.', 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af?auto=format&fit=crop&q=80&w=400', 2500000.0, 1, 'Listrik,Air,WiFi,Kebersihan,Keamanan,Parkir');

-- 11. Seed transactions
INSERT IGNORE INTO transactions (invoice_number, date_str, amount, status, property_name, user_id, transaction_type, property_id, room_id) VALUES
('INV-KSM-0526-001', '5 Mei 2026', 4500000.0, 'failed', 'Premium Residence Ubud (Kamar 2A)', (SELECT id_int FROM users WHERE email = 'budi@email.com'), 'arrears', (SELECT id_int FROM properties WHERE name = 'Premium Residence Ubud'), (SELECT id FROM rooms WHERE property_id = (SELECT id_int FROM properties WHERE name = 'Premium Residence Ubud') AND room_number = 'Kamar 2A')),
('INV-KSM-0426-001', '5 Apr 2026', 4500000.0, 'success', 'Premium Residence Ubud (Kamar 2A)', (SELECT id_int FROM users WHERE email = 'budi@email.com'), 'monthly', (SELECT id_int FROM properties WHERE name = 'Premium Residence Ubud'), (SELECT id FROM rooms WHERE property_id = (SELECT id_int FROM properties WHERE name = 'Premium Residence Ubud') AND room_number = 'Kamar 2A')),
('INV-KSM-0326-001', '5 Mar 2026', 4550000.0, 'success', 'Premium Residence Ubud (Kamar 2A)', (SELECT id_int FROM users WHERE email = 'budi@email.com'), 'rental', (SELECT id_int FROM properties WHERE name = 'Premium Residence Ubud'), (SELECT id FROM rooms WHERE property_id = (SELECT id_int FROM properties WHERE name = 'Premium Residence Ubud') AND room_number = 'Kamar 2A'));
