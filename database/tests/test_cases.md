# Test Cases — Flight Booking System
**Group-3 | Advanced Database Systems**

---

## TC-01: Schema Integrity Tests

| ID | Test Case | Steps | Expected Result | Status |
|---|---|---|---|---|
| TC-01-01 | All 17 tables exist | `SHOW TABLES FROM flight_booking;` | 17 tables listed | ✅ |
| TC-01-02 | Foreign keys enforced | `INSERT INTO flights (..., airline_id=999...)` | ERROR 1452: foreign key violation | ✅ |
| TC-01-03 | CHECK constraint on flight times | `INSERT INTO flights (..., arrival_time < departure_time)` | ERROR: check constraint `chk_flight_times` violated | ✅ |
| TC-01-04 | ENUM enforced on booking_status | `UPDATE bookings SET booking_status = 'unknown'` | ERROR: invalid value for ENUM | ✅ |
| TC-01-05 | Unique booking_ref enforced | Insert two bookings with same `booking_ref` | ERROR 1062: duplicate entry | ✅ |
| TC-01-06 | Unique seat per flight enforced | Insert two seats with same flight_id + seat_number | ERROR 1062: duplicate entry | ✅ |

---

## TC-02: Booking Flow Tests

| ID | Test Case | Steps | Expected Result | Status |
|---|---|---|---|---|
| TC-02-01 | Book an available seat | `CALL sp_book_seat(1, 1, '20A', 3, 1, @ref, @res); SELECT @res;` | `OK: booking created — ref XXXXXXXX` | ✅ |
| TC-02-02 | Verify seat status changes to reserved | After TC-02-01: `SELECT seat_status FROM seats WHERE seat_number='20A' AND flight_id=1` | `reserved` | ✅ |
| TC-02-03 | Book an already-reserved seat | Call sp_book_seat again for same seat | `ERROR: seat 20A is not available — status: reserved` | ✅ |
| TC-02-04 | Cancel a confirmed booking | `CALL sp_cancel_booking(1, 'Test cancel', @res); SELECT @res;` | `OK: booking 1 cancelled successfully` | ✅ |
| TC-02-05 | Verify seat released after cancel | After TC-02-04: `SELECT seat_status FROM seats WHERE seat_id = 2` | `available` | ✅ |
| TC-02-06 | Cancel an already-cancelled booking | Call sp_cancel_booking again on same booking | `ERROR: booking cannot be cancelled — current status is cancelled` | ✅ |
| TC-02-07 | Confirm booking without completed payment | `CALL sp_confirm_booking(2, @res)` (booking 2 payment is pending) | `ERROR: payment not completed — cannot confirm booking` | ✅ |

---

## TC-03: Concurrency Tests (Double-Booking Prevention)

| ID | Test Case | Steps | Expected Result |
|---|---|---|---|
| TC-03-01 | Simultaneous booking — Session A wins | Open two MySQL sessions. Both call `sp_book_seat(...)` for same seat at same time | Session A: OK. Session B: ERROR — seat not available |
| TC-03-02 | SELECT FOR UPDATE blocks second session | Session A: begin txn + `SELECT ... FOR UPDATE` on seat. Session B: try same | Session B hangs until A commits |
| TC-03-03 | No orphaned reserved seats on failure | Force an error between seat update and booking insert | ROLLBACK returns seat to `available` |

**How to run TC-03-01:**
```sql
-- Session A
START TRANSACTION;
SELECT seat_id, seat_status FROM seats WHERE flight_id=1 AND seat_number='10A' FOR UPDATE;
-- (pause here — now open Session B and run the same)

-- Session B (in a different connection)
START TRANSACTION;
SELECT seat_id, seat_status FROM seats WHERE flight_id=1 AND seat_number='10A' FOR UPDATE;
-- Session B blocks here.

-- Back to Session A
UPDATE seats SET seat_status='reserved' WHERE flight_id=1 AND seat_number='10A';
COMMIT;
-- Now Session B unblocks, reads seat_status='reserved', and should rollback.
```

---

## TC-04: Trigger Tests

| ID | Test Case | Steps | Expected Result |
|---|---|---|---|
| TC-04-01 | Booking insert creates audit log | Insert new booking → `SELECT * FROM audit_logs ORDER BY log_id DESC LIMIT 1` | Row with `action = 'booking_created'` and JSON new_value |
| TC-04-02 | Booking status change creates audit log | `UPDATE bookings SET booking_status='confirmed' WHERE booking_id=2` → check audit_logs | Row with `action = 'status_changed_to_confirmed'` |
| TC-04-03 | Price change populates flight_price_history | `UPDATE flights SET base_price=275.00 WHERE flight_id=1` → `SELECT * FROM flight_price_history` | Row with old_price=250.00, new_price=275.00 |
| TC-04-04 | Price change also creates audit log | Same as TC-04-03, then check audit_logs | Row with `action = 'price_updated'`, JSON old/new values |
| TC-04-05 | No price history row if price unchanged | `UPDATE flights SET status='delayed' WHERE flight_id=1` | `flight_price_history` count unchanged |

---

## TC-05: RBAC Permission Tests

| ID | Test Case | Steps | Expected Result |
|---|---|---|---|
| TC-05-01 | fb_app cannot read raw bookings table | Connect as fb_app: `SELECT * FROM bookings` | ERROR 1142: SELECT command denied |
| TC-05-02 | fb_app can read v_passenger_bookings | Connect as fb_app: `SELECT * FROM v_passenger_bookings WHERE passenger_id=1` | Returns booking rows for passenger 1 |
| TC-05-03 | fb_staff cannot delete flights | Connect as fb_staff: `DELETE FROM flights WHERE flight_id=1` | ERROR 1142: DELETE command denied |
| TC-05-04 | fb_app cannot access audit_logs | Connect as fb_app: `SELECT * FROM audit_logs` | ERROR 1142: SELECT command denied |

---

## TC-06: View Tests

| ID | Test Case | Steps | Expected Result |
|---|---|---|---|
| TC-06-01 | v_flight_availability shows correct seat counts | `SELECT * FROM v_flight_availability WHERE flight_id=1` | Counts match seats table status breakdown |
| TC-06-02 | v_occupancy_report calculates correctly | `SELECT * FROM v_occupancy_report WHERE flight_id=1` | occupancy_pct = (booked+reserved)/total * 100 |
| TC-06-03 | v_revenue_report totals are correct | `SELECT * FROM v_revenue_report WHERE flight_id=1` | net_revenue = gross - refunds |

---

## TC-07: Data Validation Tests

| ID | Test Case | Steps | Expected Result |
|---|---|---|---|
| TC-07-01 | Duplicate email rejected | Insert passenger with existing email | ERROR 1062: duplicate entry for uq_passenger_email |
| TC-07-02 | Refund cannot exceed payment amount | `UPDATE payments SET refund_amount=9999.00 WHERE payment_id=1` | ERROR: check constraint `chk_refund_le_amount` violated |
| TC-07-03 | Booking ref must be unique | Insert two bookings with same booking_ref | ERROR 1062: duplicate entry for uq_booking_ref |

---

## TC-08: Query Performance Tests

| ID | Test Case | Steps | Expected Result |
|---|---|---|---|
| TC-08-01 | Q1 uses index | `EXPLAIN` Q1 flight search query | type = range, key = idx_flights_route_date |
| TC-08-02 | Q2 uses index | `EXPLAIN` Q2 seat availability query | type = ref, key = idx_seats_status |
| TC-08-03 | Q3 uses index | `EXPLAIN` Q3 booking history query | type = ref, key = idx_bookings_passenger |

---

## Bug Tracking Template

| Bug ID | Description | Severity | Steps to Reproduce | Status |
|---|---|---|---|---|
| BUG-001 | flight_price_history never populated | High | Update flight price, check table | Fixed — added trg_flight_price_change |
| BUG-002 | sp_confirm_booking allowed without payment | Medium | Call confirm on booking with pending payment | Fixed — added payment status check |
| BUG-003 | v_passenger_bookings exposes all passengers | Medium | Query view without WHERE clause | Documented — enforce filter in application |
