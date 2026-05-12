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
-- 6. FLIGHTS
-- ============================================================
CREATE TABLE IF NOT EXISTS flights (
    flight_id         INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    flight_number     VARCHAR(10)      NOT NULL,
    airline_id        INT UNSIGNED     NOT NULL,
    aircraft_id       INT UNSIGNED     NOT NULL,
    origin_airport_id INT UNSIGNED     NOT NULL,
    dest_airport_id   INT UNSIGNED     NOT NULL,
    departure_time    DATETIME         NOT NULL,
    arrival_time      DATETIME         NOT NULL,
    base_price        DECIMAL(10, 2)   NOT NULL,
    status            ENUM('scheduled','boarding','departed','arrived','cancelled','delayed')
                                       NOT NULL DEFAULT 'scheduled',
    created_at        DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP
                                       ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (flight_id),
    CONSTRAINT fk_flights_airline
        FOREIGN KEY (airline_id) REFERENCES airlines (airline_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_flights_aircraft
        FOREIGN KEY (aircraft_id) REFERENCES aircraft (aircraft_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_flights_origin
        FOREIGN KEY (origin_airport_id) REFERENCES airports (airport_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_flights_dest
        FOREIGN KEY (dest_airport_id) REFERENCES airports (airport_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_flight_times CHECK (arrival_time > departure_time),
    INDEX idx_flights_route_date (origin_airport_id, dest_airport_id, departure_time),
    INDEX idx_flights_airline (airline_id),
    INDEX idx_flights_departure (departure_time),
    INDEX idx_flights_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 7. SEATS
-- ============================================================
CREATE TABLE IF NOT EXISTS seats (
    seat_id       INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    flight_id     INT UNSIGNED     NOT NULL,
    aircraft_id   INT UNSIGNED     NOT NULL,
    seat_number   VARCHAR(5)       NOT NULL,
    class_id      TINYINT UNSIGNED  NOT NULL,
    seat_status   ENUM('available','reserved','booked','unavailable')
                                   NOT NULL DEFAULT 'available',
    extra_price   DECIMAL(8, 2)    NOT NULL DEFAULT 0.00,
    created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP
                                   ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (seat_id),
    UNIQUE KEY uq_seat_per_flight (flight_id, seat_number),
    CONSTRAINT fk_seats_flight
        FOREIGN KEY (flight_id) REFERENCES flights (flight_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_seats_aircraft
        FOREIGN KEY (aircraft_id) REFERENCES aircraft (aircraft_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_seats_class
        FOREIGN KEY (class_id) REFERENCES seat_classes (class_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_seats_status (flight_id, seat_status),
    INDEX idx_seats_class (class_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 8. PASSENGERS
-- ============================================================
CREATE TABLE IF NOT EXISTS passengers (
    passenger_id      INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    first_name        VARCHAR(80)      NOT NULL,
    last_name         VARCHAR(80)      NOT NULL,
    email             VARCHAR(180)     NOT NULL,
    phone             VARCHAR(25)      DEFAULT NULL,
    date_of_birth     DATE             DEFAULT NULL,
    passport_number   VARCHAR(30)      DEFAULT NULL,
    nationality       VARCHAR(80)      DEFAULT NULL,
    password_hash     VARCHAR(255)     NOT NULL,
    city              VARCHAR(100)     DEFAULT NULL,
    is_active         TINYINT(1)       NOT NULL DEFAULT 1,
    created_at        DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP
                                       ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (passenger_id),
    UNIQUE KEY uq_passenger_email (email),
    UNIQUE KEY uq_passport (passport_number),
    INDEX idx_passengers_name (last_name, first_name),
    INDEX idx_passengers_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

