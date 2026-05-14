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
-- 12. AUDIT LOG
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id        BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    user_id       INT UNSIGNED     DEFAULT NULL,
    action        VARCHAR(80)      NOT NULL,
    entity_type   VARCHAR(50)      NOT NULL,
    entity_id     INT UNSIGNED     NOT NULL,
    old_value     JSON             DEFAULT NULL,
    new_value     JSON             DEFAULT NULL,
    ip_address    VARCHAR(45)      DEFAULT NULL,
    user_agent    VARCHAR(512)     DEFAULT NULL,
    created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (log_id),
    INDEX idx_audit_user (user_id),
    INDEX idx_audit_entity (entity_type, entity_id),
    INDEX idx_audit_action (action),
    INDEX idx_audit_created (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 13. DISTRIBUTED PARTITIONING SUPPORT
-- ============================================================
CREATE TABLE IF NOT EXISTS data_partitions (
    partition_id    INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    partition_key   VARCHAR(50)    NOT NULL,
    partition_type  ENUM('region','airline') NOT NULL,
    node_host       VARCHAR(150)   NOT NULL,
    is_primary      TINYINT(1)     NOT NULL DEFAULT 1,
    created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (partition_id),
    UNIQUE KEY uq_partition_key (partition_key, partition_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 14. SESSION / TOKEN TABLE (security)
-- ============================================================
CREATE TABLE IF NOT EXISTS user_sessions (
    session_id    BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    user_id       INT UNSIGNED     NOT NULL,
    token_hash    VARCHAR(255)     NOT NULL,
    ip_address    VARCHAR(45)      DEFAULT NULL,
    user_agent    VARCHAR(512)     DEFAULT NULL,
    expires_at    DATETIME         NOT NULL,
    revoked       TINYINT(1)       NOT NULL DEFAULT 0,
    created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (session_id),
    UNIQUE KEY uq_token_hash (token_hash),
    CONSTRAINT fk_sessions_user
        FOREIGN KEY (user_id) REFERENCES users (user_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_sessions_user (user_id),
    INDEX idx_sessions_expires (expires_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- 15. FLIGHT PRICE HISTORY (for revenue analytics)
-- ============================================================
CREATE TABLE IF NOT EXISTS flight_price_history (
    price_history_id  INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    flight_id         INT UNSIGNED   NOT NULL,
    class_id          TINYINT UNSIGNED NOT NULL,
    old_price         DECIMAL(10, 2) NOT NULL,
    new_price         DECIMAL(10, 2) NOT NULL,
    changed_by        INT UNSIGNED   DEFAULT NULL,
    changed_at        DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (price_history_id),
    CONSTRAINT fk_price_hist_flight
        FOREIGN KEY (flight_id) REFERENCES flights (flight_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_price_hist_class
        FOREIGN KEY (class_id) REFERENCES seat_classes (class_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_price_hist_flight (flight_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================================
-- SEED DATA — REFERENCE TABLES
-- ============================================================

