-- ============================================================
-- FLIGHT BOOKING SYSTEM — PRODUCTION-READY MySQL SCHEMA
-- GROUP-3 | Advanced Database Systems
-- ============================================================
CREATE DATABASE IF NOT EXISTS flight_booking;
USE flight_booking;

SET NAMES utf8mb4;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'STRICT_ALL_TABLES,NO_ENGINE_SUBSTITUTION';--

-- ============================================================
-- TASK 2: QUERY OPTIMIZATION — OPTIMIZED SQL QUERIES
-- ============================================================

-- Q1: Search flights by origin city, destination city, and date
-- Uses composite index idx_flights_route_date
SELECT
    f.flight_id,
    f.flight_number,
    al.airline_name,
    oa.city           AS origin_city,
    da.city           AS dest_city,
    f.departure_time,
    f.arrival_time,
    f.base_price,
    f.status,
    COUNT(s.seat_id)  AS available_seats
FROM flights f
JOIN airlines  al ON al.airline_id        = f.airline_id
JOIN airports  oa ON oa.airport_id        = f.origin_airport_id
JOIN airports  da ON da.airport_id        = f.dest_airport_id
LEFT JOIN seats s ON s.flight_id          = f.flight_id
                  AND s.seat_status       = 'available'
WHERE oa.city           = 'Addis Ababa'
  AND da.city           = 'Nairobi'
  AND DATE(f.departure_time) = '2026-05-01'
  AND f.status NOT IN ('cancelled')
GROUP BY f.flight_id
ORDER BY f.departure_time;

-- Q2: Check seat availability for a specific flight
-- Uses idx_seats_status
SELECT
    s.seat_number,
    sc.class_name,
    s.seat_status,
    (f.base_price + s.extra_price) AS total_seat_price
FROM seats s
JOIN seat_classes sc ON sc.class_id = s.class_id
JOIN flights      f  ON f.flight_id = s.flight_id
WHERE s.flight_id   = 1
  AND s.seat_status = 'available'
ORDER BY sc.class_id, s.seat_number;

-- Q3: Passenger booking history
-- Uses idx_bookings_passenger
SELECT
    b.booking_ref,
    f.flight_number,
    oa.city           AS origin,
    da.city           AS destination,
    f.departure_time,
    s.seat_number,
    sc.class_name,
    b.booking_status,
    b.total_price,
    p.payment_status
FROM bookings b
JOIN flights       f  ON f.flight_id  = b.flight_id
JOIN airports      oa ON oa.airport_id = f.origin_airport_id
JOIN airports      da ON da.airport_id = f.dest_airport_id
JOIN seats         s  ON s.seat_id    = b.seat_id
JOIN seat_classes  sc ON sc.class_id  = b.class_id
LEFT JOIN payments p  ON p.booking_id = b.booking_id
WHERE b.passenger_id = 1
ORDER BY b.reserved_at DESC;

-- Q4: Daily flight occupancy rates
SELECT
    f.flight_id,
    f.flight_number,
    DATE(f.departure_time)                                   AS flight_date,
    COUNT(s.seat_id)                                         AS total_seats,
    SUM(CASE WHEN s.seat_status = 'booked' THEN 1 ELSE 0 END) AS booked_seats,
    ROUND(
        100.0 * SUM(CASE WHEN s.seat_status = 'booked' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(s.seat_id), 0), 2
    )                                                        AS occupancy_pct
FROM flights f
JOIN seats s ON s.flight_id = f.flight_id
WHERE DATE(f.departure_time) = CURDATE()
GROUP BY f.flight_id
ORDER BY occupancy_pct DESC;

-- Q5: Revenue per flight
SELECT
    f.flight_id,
    f.flight_number,
    al.airline_name,
    DATE(f.departure_time)          AS flight_date,
    COUNT(DISTINCT b.booking_id)    AS total_bookings,
    SUM(py.amount)                  AS gross_revenue,
    SUM(py.refund_amount)           AS total_refunds,
    SUM(py.amount - py.refund_amount) AS net_revenue
FROM flights  f
JOIN airlines al ON al.airline_id  = f.airline_id
JOIN bookings b  ON b.flight_id    = f.flight_id
                 AND b.booking_status IN ('confirmed','completed')
JOIN payments py ON py.booking_id  = b.booking_id
                 AND py.payment_status IN ('completed','partially_refunded')
GROUP BY f.flight_id
ORDER BY net_revenue DESC;

