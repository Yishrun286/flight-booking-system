# Optimized Queries — Flight Booking System
**Group-3 | Advanced Database Systems**

---

## Query Optimization Strategy

Each query below is designed to use specific indexes defined in `001_initial_schema.sql`. The `EXPLAIN` notes show which index MySQL selects and why the query is efficient.

---

## Q1 — Flight Search by Route and Date

**Purpose:** Customer-facing flight search. Most frequently executed query in the system.

**Index used:** `idx_flights_route_date (origin_airport_id, dest_airport_id, departure_time)`

```sql
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
```

**EXPLAIN result (expected):**
```
id | select_type | table | type  | key                    | rows | Extra
1  | SIMPLE      | f     | range | idx_flights_route_date | ~5   | Using index condition; Using where
1  | SIMPLE      | oa    | eq_ref| PRIMARY                | 1    |
1  | SIMPLE      | da    | eq_ref| PRIMARY                | 1    |
1  | SIMPLE      | al    | eq_ref| PRIMARY                | 1    |
1  | SIMPLE      | s     | ref   | idx_seats_status       | ~8   |
```

**Why it's fast:** The composite index covers the three most selective filter columns together. MySQL can range-scan on `departure_time` after matching the two airport IDs, avoiding a full table scan on `flights`.

---

## Q2 — Seat Availability for a Specific Flight

**Purpose:** Show available seats to a customer before booking. Called when a user selects a flight.

**Index used:** `idx_seats_status (flight_id, seat_status)`

```sql
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
```

**EXPLAIN result (expected):**
```
id | table | type | key              | rows | Extra
1  | s     | ref  | idx_seats_status | ~10  | Using index condition; Using filesort
1  | sc    | eq_ref | PRIMARY        | 1    |
1  | f     | eq_ref | PRIMARY        | 1    |
```

**Why it's fast:** Both `flight_id` and `seat_status` are in the same composite index. MySQL satisfies both filter conditions from the index without touching the full row data.

---

## Q3 — Passenger Booking History

**Purpose:** Show a passenger their complete booking history. Used on customer profile page.

**Index used:** `idx_bookings_passenger (passenger_id)`

```sql
SELECT
    b.booking_ref,
    f.flight_number,
    al.airline_name,
    oa.city           AS origin,
    da.city           AS destination,
    f.departure_time,
    s.seat_number,
    sc.class_name,
    b.booking_status,
    b.total_price,
    py.payment_status
FROM bookings      b
JOIN flights       f  ON f.flight_id   = b.flight_id
JOIN airlines      al ON al.airline_id = f.airline_id
JOIN airports      oa ON oa.airport_id = f.origin_airport_id
JOIN airports      da ON da.airport_id = f.dest_airport_id
JOIN seats         s  ON s.seat_id     = b.seat_id
JOIN seat_classes  sc ON sc.class_id   = b.class_id
LEFT JOIN payments py ON py.booking_id = b.booking_id
WHERE b.passenger_id = 1
ORDER BY b.reserved_at DESC;
```

**EXPLAIN result (expected):**
```
id | table | type   | key                    | rows | Extra
1  | b     | ref    | idx_bookings_passenger | ~3   | Using index condition
1  | f     | eq_ref | PRIMARY                | 1    |
...
```

---

## Q4 — Daily Flight Occupancy Rates

**Purpose:** Admin dashboard widget. Shows which flights are filling up today.

```sql
SELECT
    f.flight_id,
    f.flight_number,
    DATE(f.departure_time)                                                AS flight_date,
    COUNT(s.seat_id)                                                      AS total_seats,
    SUM(CASE WHEN s.seat_status = 'booked'   THEN 1 ELSE 0 END)          AS booked_seats,
    SUM(CASE WHEN s.seat_status = 'reserved' THEN 1 ELSE 0 END)          AS reserved_seats,
    ROUND(
        100.0 * SUM(CASE WHEN s.seat_status IN ('booked','reserved') THEN 1 ELSE 0 END)
        / NULLIF(COUNT(s.seat_id), 0), 2
    )                                                                     AS occupancy_pct
FROM flights f
JOIN seats s ON s.flight_id = f.flight_id
WHERE DATE(f.departure_time) = CURDATE()
GROUP BY f.flight_id
ORDER BY occupancy_pct DESC;
```

**Note:** `NULLIF(COUNT(...), 0)` prevents division-by-zero when a flight has no seats loaded yet.

---

## Q5 — Revenue per Flight

**Purpose:** Finance/admin reporting. Shows gross revenue, refunds, and net revenue per flight.

**Indexes used:** `idx_bookings_flight`, `idx_payments_booking`, `idx_payments_status`

```sql
SELECT
    f.flight_id,
    f.flight_number,
    al.airline_name,
    DATE(f.departure_time)            AS flight_date,
    COUNT(DISTINCT b.booking_id)      AS total_bookings,
    COALESCE(SUM(py.amount), 0)                       AS gross_revenue,
    COALESCE(SUM(py.refund_amount), 0)                AS total_refunds,
    COALESCE(SUM(py.amount - py.refund_amount), 0)    AS net_revenue
FROM flights   f
JOIN airlines  al ON al.airline_id  = f.airline_id
LEFT JOIN bookings b  ON b.flight_id = f.flight_id
                      AND b.booking_status IN ('confirmed', 'completed')
LEFT JOIN payments py ON py.booking_id = b.booking_id
                      AND py.payment_status IN ('completed', 'partially_refunded')
GROUP BY f.flight_id
ORDER BY net_revenue DESC;
```

**Improvement over original:** Added `COALESCE(..., 0)` to handle flights with no completed bookings, which caused NULL values in the original query result.

---

## Concurrency Query — Double-Booking Prevention

**Purpose:** Demonstrates the `SELECT ... FOR UPDATE` locking pattern used in `sp_book_seat`.

```sql
-- Run in Session A and Session B simultaneously to demonstrate locking.
-- Only one session will succeed in updating the seat.

START TRANSACTION;

SELECT seat_id, seat_status
FROM seats
WHERE flight_id = 1 AND seat_number = '10A'
FOR UPDATE;                          -- Acquires row-level exclusive lock

-- Session B will BLOCK here until Session A commits or rolls back.

UPDATE seats
SET seat_status = 'reserved', updated_at = CURRENT_TIMESTAMP
WHERE flight_id = 1 AND seat_number = '10A' AND seat_status = 'available';

-- ROW_COUNT() = 1 means the update succeeded (seat was available).
-- ROW_COUNT() = 0 means another session already changed the status.

COMMIT;
```

---

## How to Run EXPLAIN

To verify indexes are being used on your MySQL instance:

```sql
EXPLAIN
SELECT f.flight_id, f.flight_number
FROM flights f
JOIN airports oa ON oa.airport_id = f.origin_airport_id
WHERE oa.city = 'Addis Ababa'
  AND DATE(f.departure_time) = '2026-05-01';
```

Look for `type = ref` or `type = range` (good) vs `type = ALL` (full table scan — bad).

Use `EXPLAIN FORMAT=JSON` for a more detailed breakdown including cost estimates.
