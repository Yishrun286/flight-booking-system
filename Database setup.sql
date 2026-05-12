-- ============================================================
-- FLIGHT BOOKING SYSTEM — PRODUCTION-READY MySQL SCHEMA
-- Group-3 | Advanced Database Systems
-- ============================================================
CREATE DATABASE IF NOT EXISTS flight_booking;
USE flight_booking;

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION';

-- ============================================================
-- 1. REGIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS regions (
    region_id     INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    region_name   VARCHAR(100)     NOT NULL,
    country       VARCHAR(100)     NOT NULL,
    created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (region_id),
    UNIQUE KEY uq_region_name (region_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 2. AIRPORTS
-- ============================================================
CREATE TABLE IF NOT EXISTS airports (
    airport_id    INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    iata_code     CHAR(3)          NOT NULL,
    airport_name  VARCHAR(150)     NOT NULL,
    city          VARCHAR(100)     NOT NULL,
    region_id     INT UNSIGNED     NOT NULL,
    timezone      VARCHAR(60)      NOT NULL DEFAULT 'UTC',
    created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (airport_id),
    UNIQUE KEY uq_iata_code (iata_code),
    CONSTRAINT fk_airports_region
        FOREIGN KEY (region_id) REFERENCES regions (region_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_airports_city (city)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 3. AIRLINES
-- ============================================================
CREATE TABLE IF NOT EXISTS airlines (
    airline_id    INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    iata_code     CHAR(2)          NOT NULL,
    airline_name  VARCHAR(150)     NOT NULL,
    country       VARCHAR(100)     NOT NULL,
    is_active     TINYINT(1)       NOT NULL DEFAULT 1,
    created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (airline_id),
    UNIQUE KEY uq_airline_iata (iata_code),
    INDEX idx_airlines_name (airline_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 4. AIRCRAFT
-- ============================================================
CREATE TABLE IF NOT EXISTS aircraft (
    aircraft_id       INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    airline_id        INT UNSIGNED     NOT NULL,
    registration_code VARCHAR(20)      NOT NULL,
    model             VARCHAR(80)      NOT NULL,
    total_seats       SMALLINT UNSIGNED NOT NULL,
    is_active         TINYINT(1)       NOT NULL DEFAULT 1,
    created_at        DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (aircraft_id),
    UNIQUE KEY uq_registration (registration_code),
    CONSTRAINT fk_aircraft_airline
        FOREIGN KEY (airline_id) REFERENCES airlines (airline_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 5. SEAT CLASSES
-- ============================================================
CREATE TABLE IF NOT EXISTS seat_classes (
    class_id      TINYINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    class_code    CHAR(1)           NOT NULL,
    class_name    VARCHAR(30)       NOT NULL,
    PRIMARY KEY (class_id),
    UNIQUE KEY uq_class_code (class_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
