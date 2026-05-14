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

-- Secure view: flight availability (read-only for public)
CREATE OR REPLACE VIEW v_flight_availability AS
SELECT
    f.flight_id,
    f.flight_number,
    al.airline_name,
    oa.city           AS origin,
    da.city           AS destination,
    f.departure_time,
    f.arrival_time,
    f.base_price,
    f.status,
    SUM(CASE WHEN s.seat_status = 'available' THEN 1 ELSE 0 END) AS available_seats
FROM flights   f
JOIN airlines  al ON al.airline_id  = f.airline_id
JOIN airports  oa ON oa.airport_id  = f.origin_airport_id
JOIN airports  da ON da.airport_id  = f.dest_airport_id
LEFT JOIN seats s  ON s.flight_id   = f.flight_id
GROUP BY f.flight_id;

-- Audit trigger: log every booking status change
DELIMITER $$

DROP TRIGGER IF EXISTS trg_booking_audit_update;
CREATE TRIGGER trg_booking_audit_update
AFTER UPDATE ON bookings
FOR EACH ROW
BEGIN
    IF OLD.booking_status <> NEW.booking_status THEN
        INSERT INTO audit_logs (entity_type, entity_id, action, old_value, new_value)
        VALUES (
            'booking',
            NEW.booking_id,
            CONCAT('status_changed_to_', NEW.booking_status),
            JSON_OBJECT('booking_status', OLD.booking_status),
            JSON_OBJECT('booking_status', NEW.booking_status)
        );
    END IF;
END$$

-- Audit trigger: log new bookings
DROP TRIGGER IF EXISTS trg_booking_audit_insert;
CREATE TRIGGER trg_booking_audit_insert
AFTER INSERT ON bookings
FOR EACH ROW
BEGIN
    INSERT INTO audit_logs (entity_type, entity_id, action, new_value)
    VALUES (
        'booking',
        NEW.booking_id,
        'booking_created',
        JSON_OBJECT(
            'booking_ref',    NEW.booking_ref,
            'passenger_id',   NEW.passenger_id,
            'flight_id',      NEW.flight_id,
            'seat_id',        NEW.seat_id,
            'booking_status', NEW.booking_status,
            'total_price',    NEW.total_price
        )
    );
    
END$$

-- Stored procedure: cancel a booking with refund check
DROP PROCEDURE IF EXISTS sp_cancel_booking;
CREATE PROCEDURE sp_cancel_booking(
    IN  p_booking_id  INT UNSIGNED,
    IN  p_reason      VARCHAR(500),
    OUT p_result      VARCHAR(100)
)
BEGIN
    DECLARE v_status    VARCHAR(20);
    DECLARE v_seat_id   INT UNSIGNED;

    START TRANSACTION;

    SELECT booking_status, seat_id
    INTO   v_status, v_seat_id
    FROM   bookings
    WHERE  booking_id = p_booking_id
    FOR UPDATE;

    IF v_status IN ('cancelled', 'completed', 'no_show') THEN
        SET p_result = 'ERROR: booking cannot be cancelled';
        ROLLBACK;
    ELSE
        UPDATE bookings
        SET    booking_status      = 'cancelled',
               cancelled_at        = CURRENT_TIMESTAMP,
               cancellation_reason = p_reason
        WHERE  booking_id = p_booking_id;

        UPDATE seats
        SET    seat_status = 'available',
               updated_at  = CURRENT_TIMESTAMP
        WHERE  seat_id = v_seat_id;

        SET p_result = 'OK: booking cancelled';
        COMMIT;
    END IF;
END$$

DELIMITER ;
