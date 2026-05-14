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
-- TASK 4: MySQL USER GRANTS (RBAC at DB level)
-- ============================================================

-- Admin user — full control
CREATE USER IF NOT EXISTS 'fb_admin'@'%' IDENTIFIED BY 'change_this_password';
GRANT  SELECT, INSERT, UPDATE  ON flight_booking.* TO 'fb_admin'@'%';

-- Airline staff — manage flights and seats; read bookings
CREATE USER IF NOT EXISTS 'fb_staff'@'%' IDENTIFIED BY 'change_this_password';
GRANT SELECT, INSERT, UPDATE ON flight_booking.flights   TO 'fb_staff'@'%';
GRANT SELECT, UPDATE         ON flight_booking.seats     TO 'fb_staff'@'%';
GRANT SELECT                 ON flight_booking.bookings  TO 'fb_staff'@'%';
GRANT SELECT                 ON flight_booking.passengers TO 'fb_staff'@'%';

-- Customer app user — limited to booking flow
CREATE USER IF NOT EXISTS 'fb_app'@'%' IDENTIFIED BY 'change_this_password';
GRANT SELECT                 ON flight_booking.v_flight_availability TO 'fb_app'@'%';
GRANT SELECT                 ON flight_booking.v_passenger_bookings  TO 'fb_app'@'%';
GRANT SELECT, UPDATE         ON flight_booking.seats     TO 'fb_app'@'%';
GRANT SELECT, INSERT, UPDATE ON flight_booking.bookings  TO 'fb_app'@'%';
GRANT SELECT, INSERT         ON flight_booking.payments  TO 'fb_app'@'%';
GRANT SELECT                 ON flight_booking.flights   TO 'fb_app'@'%';
GRANT SELECT                 ON flight_booking.passengers TO 'fb_app'@'%';

FLUSH PRIVILEGES;

-- ============================================================
-- RE-ENABLE FOREIGN KEY CHECKS
-- ============================================================
SET foreign_key_checks = 1;

-- ============================================================
-- DATABASE DESIGN COMPLETE.
