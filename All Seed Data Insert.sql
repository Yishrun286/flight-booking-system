-- ============================================================
-- FLIGHT BOOKING SYSTEM — PRODUCTION-READY MySQL SCHEMA
-- Group-3 | Advanced Database Systems
-- ============================================================
CREATE DATABASE IF NOT EXISTS flight_booking;
USE flight_booking;

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION';--

-- ============================================================
-- FLIGHT BOOKING SYSTEM — PRODUCTION-READY MySQL SCHEMA
-- Group-3 | Advanced Database Systems
-- ============================================================
CREATE DATABASE IF NOT EXISTS flight_booking;
USE flight_booking;

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION';--

INSERT IGNORE INTO seat_classes (class_code, class_name) VALUES
    ('F', 'First Class'),
    ('B', 'Business Class'),
    ('E', 'Economy Class');

INSERT IGNORE INTO payment_methods (method_name) VALUES
    ('Telebirr'),
    ('Card'),
    ('Bank Transfer'),
    ('M-Pesa');

INSERT IGNORE INTO roles (role_name, description) VALUES
    ('admin',         'Full system control'),
    ('airline_staff', 'Manage flights and seats'),
    ('customer',      'Book and manage own tickets');

INSERT IGNORE INTO permissions (permission_name, description) VALUES
    ('flight.create',   'Create new flights'),
    ('flight.update',   'Update flight details'),
    ('flight.delete',   'Remove flights'), 
    ('flight.view',     'View flight list and details'),
    ('seat.manage',     'Manage seat availability'),
    ('booking.create',  'Create bookings'),
    ('booking.cancel',  'Cancel bookings'),
    ('booking.view_all','View all bookings'),
    ('payment.view',    'View payment records'),
    ('payment.refund',  'Process refunds'),
    ('user.manage',     'Manage user accounts'),
    ('report.view',     'Access reports and analytics');

-- admin gets all permissions
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT 1, permission_id FROM permissions;

-- airline_staff
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT 2, permission_id FROM permissions
WHERE permission_name IN ('flight.create','flight.update','flight.view','seat.manage','booking.view_all','report.view');

-- customer
INSERT IGNORE INTO role_permissions (role_id, permission_id)
SELECT 3, permission_id FROM permissions
WHERE permission_name IN ('flight.view','booking.create','booking.cancel');

-- Regions
INSERT IGNORE INTO regions (region_name, country) VALUES
    ('Addis Ababa', 'Ethiopia'),
    ('Nairobi',     'Kenya'),
    ('Hawassa',     'Ethiopia'),
    ('Adama',       'Ethiopia');

-- Airports
INSERT IGNORE INTO airports (iata_code, airport_name, city, region_id, timezone) VALUES
    ('ADD', 'Bole International Airport',    'Addis Ababa', 1, 'Africa/Addis_Ababa'), 
    ('NBO', 'Jomo Kenyatta International',   'Nairobi',     2, 'Africa/Nairobi'),
    ('AWA', 'Hawassa Airport',               'Hawassa',     3, 'Africa/Addis_Ababa'),
    ('DIR', 'Adama Airport',                 'Adama',       4, 'Africa/Addis_Ababa');

-- Airlines
INSERT IGNORE INTO airlines (iata_code, airline_name, country) VALUES
    ('ET', 'Ethiopian Airlines', 'Ethiopia'),
    ('KQ', 'Kenya Airways',      'Kenya');

-- Aircraft
INSERT IGNORE INTO aircraft (airline_id, registration_code, model, total_seats) VALUES
    (1, 'ET-ALJ', 'Boeing 737-800', 150),
    (2, 'KQ-ABC', 'Airbus A320',    180);

-- Flights
INSERT IGNORE INTO flights (flight_number, airline_id, aircraft_id, origin_airport_id, dest_airport_id, departure_time, arrival_time, base_price) VALUES
    ('ET101', 1, 1, 1, 2, '2026-05-01 08:00:00', '2026-05-01 10:30:00', 250.00),
    ('KQ202', 2, 2, 2, 1, '2026-05-02 14:00:00', '2026-05-02 16:30:00', 230.00);

-- Seats for Flight 1 (ET101)
INSERT IGNORE INTO seats (flight_id, aircraft_id, seat_number, class_id, seat_status) VALUES
    (1, 1, '1A', 1, 'available'),
    (1, 1, '1B', 1, 'booked'),
    (1, 1, '10A', 3, 'available'),
    (1, 1, '10B', 3, 'available');

-- Seats for Flight 2 (KQ202)
INSERT IGNORE INTO seats (flight_id, aircraft_id, seat_number, class_id, seat_status) VALUES
    (2, 2, '2A', 2, 'available'),
    (2, 2, '2B', 2, 'available'),
    (2, 2, '20A', 3, 'available');

-- Passengers
INSERT IGNORE INTO passengers (first_name, last_name, email, phone, city, password_hash) VALUES
    ('Abel',  'Kebede', 'abel@example.com',  '+251911000001', 'Addis Ababa', SHA2('pass_abel_change_me',  256)),
    ('Sara',  'Tadesse','sara@example.com',  '+251911000002', 'Adama',       SHA2('pass_sara_change_me',  256)),
    ('Dawit', 'Haile',  'dawit@example.com', '+251911000003', 'Hawassa',     SHA2('pass_dawit_change_me', 256));

-- Users (linked to passengers)
INSERT IGNORE INTO users (passenger_id, username, email, password_hash, role_id) VALUES
    (1, 'abel_k',  'abel@example.com',  SHA2('pass_abel_change_me',  256), 3),
    (2, 'sara_t',  'sara@example.com',  SHA2('pass_sara_change_me',  256), 3),
    (3, 'dawit_h', 'dawit@example.com', SHA2('pass_dawit_change_me', 256), 3);

-- Admin user (no passenger link)
INSERT IGNORE INTO users (passenger_id, username, email, password_hash, role_id) VALUES
    (NULL, 'sysadmin', 'admin@flightbook.com', SHA2('admin_pass_change_me', 256), 1);

-- Bookings
INSERT IGNORE INTO bookings (booking_ref, passenger_id, flight_id, seat_id, class_id, booking_status, total_price, confirmed_at) VALUES
    ('BKAA1001', 1, 1, 1, 1, 'confirmed', 250.00, '2026-04-10 09:00:00'),
    ('BKBB2002', 2, 2, 5, 2, 'reserved',  230.00, NULL);

-- Payments
INSERT IGNORE INTO payments (booking_id, method_id, amount, currency, payment_status, transaction_ref, payment_date) VALUES
    (1, 1, 250.00, 'USD', 'completed', 'TXN-TELE-00001', '2026-04-10 09:05:00'),
    (2, 2, 230.00, 'USD', 'pending',   NULL,              NULL);

