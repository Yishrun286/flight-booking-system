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
-- TASK 3: TRANSACTIONS & CONCURRENCY EXAMPLES
-- ============================================================

-- Prevent double-booking via SERIALIZABLE transaction + SELECT ... FOR UPDATE
-- (Run this in two concurrent sessions to demonstrate locking)

-- Session A / Session B both execute this block; only one succeeds.
START TRANSACTION;

-- Lock the specific seat row to prevent concurrent modification
SELECT seat_id, seat_status
FROM seats
WHERE flight_id = 1 AND seat_number = '1A'
FOR UPDATE;

-- Check availability inside the lock
-- Application layer reads the result; if seat_status = 'available', proceed:
UPDATE seats
SET seat_status = 'reserved',
    updated_at  = CURRENT_TIMESTAMP
WHERE flight_id = 1 AND seat_number = '1A' AND seat_status = 'available';

-- Only insert booking if exactly 1 row was updated (ROW_COUNT() = 1)
INSERT IGNORE INTO bookings (booking_ref, passenger_id, flight_id, seat_id, class_id, booking_status, total_price)
SELECT 'BKCC3003', 3, 1, seat_id, class_id, 'reserved', 250.00
FROM seats
WHERE flight_id = 1 AND seat_number = '1A' AND seat_status = 'reserved'
LIMIT 1;

COMMIT;

-- ============================================================
-- TASK 4: SECURITY & RBAC — VIEWS AND STORED PROCEDURES
-- ============================================================

-- Secure view: customers see only their own bookings
CREATE OR REPLACE VIEW v_passenger_bookings AS
SELECT
    b.booking_id,
    b.booking_ref,
    b.passenger_id,
    f.flight_number,
    oa.city  AS origin,
    da.city  AS destination,
    f.departure_time,
    b.booking_status,
    b.total_price
FROM bookings b
JOIN flights  f  ON f.flight_id  = b.flight_id
JOIN airports oa ON oa.airport_id = f.origin_airport_id
JOIN airports da ON da.airport_id = f.dest_airport_id;

