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
 ============================================================
-- 9. BOOKINGS
-- ============================================================
CREATE TABLE IF NOT EXISTS bookings (
    booking_id        INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    booking_ref       VARCHAR(8)       NOT NULL,
    passenger_id      INT UNSIGNED     NOT NULL,
    flight_id         INT UNSIGNED     NOT NULL,
    seat_id           INT UNSIGNED     NOT NULL,
    class_id          TINYINT UNSIGNED  NOT NULL,
    booking_status    ENUM('reserved','confirmed','cancelled','completed','no_show')
                                       NOT NULL DEFAULT 'reserved',
    total_price       DECIMAL(10, 2)   NOT NULL,
    currency          CHAR(3)          NOT NULL DEFAULT 'USD',
    reserved_at       DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    confirmed_at      DATETIME         DEFAULT NULL,
    cancelled_at      DATETIME         DEFAULT NULL,
    completed_at      DATETIME         DEFAULT NULL,
    cancellation_reason VARCHAR(500)   DEFAULT NULL,
    created_at        DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at        DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP
                                       ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (booking_id),
    UNIQUE KEY uq_booking_ref (booking_ref),
    UNIQUE KEY uq_seat_booking (seat_id, booking_status),
    CONSTRAINT fk_bookings_passenger
        FOREIGN KEY (passenger_id) REFERENCES passengers (passenger_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_bookings_flight
        FOREIGN KEY (flight_id) REFERENCES flights (flight_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_bookings_seat
        FOREIGN KEY (seat_id) REFERENCES seats (seat_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_bookings_class
        FOREIGN KEY (class_id) REFERENCES seat_classes (class_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_bookings_passenger (passenger_id),
    INDEX idx_bookings_flight (flight_id),
    INDEX idx_bookings_status (booking_status),
    INDEX idx_bookings_ref (booking_ref),
    INDEX idx_bookings_reserved_at (reserved_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 10. PAYMENTS
-- ============================================================
CREATE TABLE IF NOT EXISTS payment_methods (
    method_id     TINYINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    method_name   VARCHAR(50)       NOT NULL,
    is_active     TINYINT(1)        NOT NULL DEFAULT 1,
    PRIMARY KEY (method_id),
    UNIQUE KEY uq_method_name (method_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS payments (
    payment_id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    booking_id            INT UNSIGNED     NOT NULL,
    method_id             TINYINT UNSIGNED  NOT NULL,
    amount                DECIMAL(10, 2)   NOT NULL,
    currency              CHAR(3)          NOT NULL DEFAULT 'USD',
    payment_status        ENUM('pending','completed','failed','refunded','partially_refunded')
                                           NOT NULL DEFAULT 'pending',
    transaction_ref       VARCHAR(128)     DEFAULT NULL,
    gateway_response_code VARCHAR(30)      DEFAULT NULL,
    payment_date          DATETIME         DEFAULT NULL,
    refund_amount         DECIMAL(10, 2)   NOT NULL DEFAULT 0.00,
    refunded_at           DATETIME         DEFAULT NULL,
    created_at            DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at            DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP
                                           ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (payment_id),
    UNIQUE KEY uq_transaction_ref (transaction_ref),
    CONSTRAINT fk_payments_booking
        FOREIGN KEY (booking_id) REFERENCES bookings (booking_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_payments_method
        FOREIGN KEY (method_id) REFERENCES payment_methods (method_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT chk_refund_le_amount CHECK (refund_amount <= amount),
    INDEX idx_payments_booking (booking_id),
    INDEX idx_payments_status (payment_status),
    INDEX idx_payments_date (payment_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 11. ROLES & USERS (RBAC)
-- ============================================================
CREATE TABLE IF NOT EXISTS roles (
    role_id     TINYINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    role_name   VARCHAR(50)       NOT NULL,
    description VARCHAR(255)      DEFAULT NULL,
    PRIMARY KEY (role_id),
    UNIQUE KEY uq_role_name (role_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS permissions (
    permission_id   SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
    permission_name VARCHAR(80)       NOT NULL,
    description     VARCHAR(255)      DEFAULT NULL,
    PRIMARY KEY (permission_id),
    UNIQUE KEY uq_permission_name (permission_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Many-to-Many: roles ↔ permissions
CREATE TABLE if not exists role_permissions (
    role_id       TINYINT UNSIGNED  NOT NULL,
    permission_id SMALLINT UNSIGNED NOT NULL,
    granted_at    DATETIME          NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (role_id, permission_id),
    CONSTRAINT fk_rp_role
        FOREIGN KEY (role_id) REFERENCES roles (role_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_rp_permission
        FOREIGN KEY (permission_id) REFERENCES permissions (permission_id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS users (
    user_id       INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    passenger_id  INT UNSIGNED     DEFAULT NULL,
    username      VARCHAR(60)      NOT NULL,
    email         VARCHAR(180)     NOT NULL,
    password_hash VARCHAR(255)     NOT NULL,
    role_id       TINYINT UNSIGNED  NOT NULL,
    is_active     TINYINT(1)       NOT NULL DEFAULT 1,
    last_login_at DATETIME         DEFAULT NULL,
    created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP
                                   ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id),
    UNIQUE KEY uq_username (username),
    UNIQUE KEY uq_user_email (email),
    CONSTRAINT fk_users_passenger
        FOREIGN KEY (passenger_id) REFERENCES passengers (passenger_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_users_role
        FOREIGN KEY (role_id) REFERENCES roles (role_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_users_role (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

