# ✈️ Flight Booking System — Database Schema

> **Advanced Database Systems 
|| Group-3|| Group members

NAME || ID

Robel Elias || MTUUR/8999/17

Yishrun legesse || MTUUR/9010/17

Yohannis Haile || MTUUR/8133/17

Dagmawi Kassahun || MTUUR/8747/17

Mekdes Mengesha || MTURR/8805/17

Alemu Melese || MTUUR/8969/17

Kemil Abdi || MTUUR/9377/17

Zufan Haile || MTUUR/8963/17

Yonas Tamirat || MTUUR/8318/17

Yemeserach Markos || MTUUR/8779/17
> Production-ready MySQL schema for a flight booking platform with RBAC, audit logging, concurrency control, and revenue analytics.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Database Schema](#database-schema)
  - [Entity Relationship Summary](#entity-relationship-summary)
  - [Tables](#tables)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Seed Data](#seed-data)
- [Optimized Queries](#optimized-queries)
- [Transactions & Concurrency](#transactions--concurrency)
- [Security & RBAC](#security--rbac)
  - [Database Users](#database-users)
  - [Application Roles](#application-roles)
  - [Views](#views)
  - [Stored Procedures](#stored-procedures)
  - [Triggers](#triggers)
- [Project Structure](#project-structure)

---

## Overview

This project implements a fully normalized, production-grade relational database for a flight booking platform. It covers:

- Flight and seat inventory management
- Passenger registration and booking lifecycle
- Payment processing with refund tracking
- Role-Based Access Control (RBAC) at both the application and MySQL user level
- Audit logging for all booking state changes
- Distributed partitioning metadata support
- Secure session/token management

---

## Database Schema

### Entity Relationship Summary

```
regions
  └── airports
        └── flights ──────────────────────────── seats
              │                                     │
              └── bookings ◄── passengers        seat_classes
                    │
                    └── payments ◄── payment_methods

airlines
  └── aircraft
        └── flights

roles ◄──── role_permissions ──► permissions
  └── users ──► passengers

audit_logs
flight_price_history
user_sessions
data_partitions
```

### Tables

| # | Table | Description |
|---|-------|-------------|
| 1 | `regions` | Geographic regions linked to airports |
| 2 | `airports` | Airports with IATA codes and timezones |
| 3 | `airlines` | Airline carriers with IATA codes |
| 4 | `aircraft` | Aircraft fleet registered to airlines |
| 5 | `seat_classes` | Seat class definitions (First, Business, Economy) |
| 6 | `flights` | Scheduled flights with status tracking |
| 7 | `seats` | Per-flight seat inventory with availability status |
| 8 | `passengers` | Passenger profiles and credentials |
| 9 | `bookings` | Booking lifecycle (reserved → confirmed → completed) |
| 10 | `payment_methods` | Supported payment methods (Telebirr, Card, etc.) |
| 11 | `payments` | Payment records with refund tracking |
| 12 | `roles` | RBAC roles (admin, airline_staff, customer) |
| 13 | `permissions` | Fine-grained permission definitions |
| 14 | `role_permissions` | Many-to-many role ↔ permission mapping |
| 15 | `users` | System users linked to roles and passengers |
| 16 | `audit_logs` | Immutable log of all entity state changes |
| 17 | `data_partitions` | Distributed partitioning metadata |
| 18 | `user_sessions` | JWT/token session management |
| 19 | `flight_price_history` | Price change history for analytics |

#### Key Design Decisions

- **`ENUM` for status fields** — enforces valid state machine transitions at the DB level for `flights.status`, `seats.seat_status`, `bookings.booking_status`, and `payments.payment_status`.
- **`CHECK` constraints** — `arrival_time > departure_time` on `flights`; `refund_amount <= amount` on `payments`.
- **`UNIQUE KEY uq_seat_booking (seat_id, booking_status)`** — prevents a seat from being double-booked.
- **JSON columns** — `audit_logs.old_value` / `new_value` store structured diffs for any entity change.
- **`ON DELETE RESTRICT`** on most FKs — prevents accidental cascade deletion of financial records.
- **`ON DELETE CASCADE`** on `seats → flights` and `user_sessions → users` — safe to cascade.

---

## Getting Started

### Prerequisites

- MySQL 8.0+ (or MariaDB 10.6+)
- A MySQL client (`mysql`, DBeaver, MySQL Workbench, etc.)

### Installation

1. **Clone the repository**

```bash
git clone https://github.com/<your-org>/flight-booking-db.git
cd flight-booking-db
```

2. **Run the schema script**

```bash
mysql -u root -p < schema.sql
```

3. **Verify the installation**

```sql
USE flight_booking;
SHOW TABLES;
```

> ⚠️ **Security Notice:** The seed data uses placeholder passwords like `pass_abel_change_me` and `admin_pass_change_me`. Change all credentials before deploying to any non-local environment.

---

## Seed Data

The schema ships with reference data to get started immediately:

| Entity | Seeded Records |
|--------|---------------|
| Seat Classes | First Class, Business Class, Economy Class |
| Payment Methods | Telebirr, Card, Bank Transfer, M-Pesa |
| Roles | admin, airline_staff, customer |
| Permissions | 12 fine-grained permissions |
| Regions | Addis Ababa, Nairobi, Hawassa, Adama |
| Airports | ADD (Bole), NBO (JKIA), AWA (Hawassa), DIR (Adama) |
| Airlines | Ethiopian Airlines (ET), Kenya Airways (KQ) |
| Aircraft | Boeing 737-800, Airbus A320 |
| Flights | ET101 (ADD→NBO), KQ202 (NBO→ADD) |
| Passengers | 3 sample passengers |
| Bookings | 1 confirmed, 1 reserved |
| Payments | 1 completed (Telebirr), 1 pending (Card) |

---

## Optimized Queries

Five production-ready queries are included, each mapped to a supporting index:

### Q1 — Search Flights by Route and Date
Uses `idx_flights_route_date (origin_airport_id, dest_airport_id, departure_time)`.

```sql
SELECT f.flight_id, f.flight_number, al.airline_name, ...
FROM flights f
JOIN airports oa ON oa.airport_id = f.origin_airport_id
WHERE oa.city = 'Addis Ababa' AND da.city = 'Nairobi'
  AND DATE(f.departure_time) = '2026-05-01'
  AND f.status NOT IN ('cancelled');
```

### Q2 — Seat Availability for a Flight
Uses `idx_seats_status (flight_id, seat_status)`.

### Q3 — Passenger Booking History
Uses `idx_bookings_passenger (passenger_id)`.

### Q4 — Daily Flight Occupancy Rate
Calculates `booked_seats / total_seats` per flight as a percentage using `NULLIF` to guard against division by zero.

### Q5 — Revenue per Flight
Computes `gross_revenue`, `total_refunds`, and `net_revenue` per flight, filtered to confirmed bookings with completed payments.

---

## Transactions & Concurrency

The schema includes a **double-booking prevention** pattern using `SELECT ... FOR UPDATE` inside a transaction:

```sql
START TRANSACTION;

-- Acquire a row-level lock on the target seat
SELECT seat_id, seat_status
FROM seats
WHERE flight_id = 1 AND seat_number = '1A'
FOR UPDATE;

-- Conditionally update — only proceeds if seat is still available
UPDATE seats
SET seat_status = 'reserved'
WHERE flight_id = 1 AND seat_number = '1A' AND seat_status = 'available';

-- Insert booking only if the update affected exactly 1 row
INSERT IGNORE INTO bookings (...) SELECT ... FROM seats WHERE ... AND seat_status = 'reserved';

COMMIT;
```

Running this block in two concurrent sessions demonstrates that only one will succeed — the second will block on the `FOR UPDATE` lock and find the seat already reserved when it proceeds.

---

## Security & RBAC

### Database Users

Three MySQL users are provisioned with least-privilege grants:

| MySQL User | Intended For | Access Level |
|------------|--------------|--------------|
| `fb_admin` | System administrators | SELECT, INSERT, UPDATE on all tables |
| `fb_staff` | Airline staff | Full access to `flights`, `seats`; read-only on `bookings`, `passengers` |
| `fb_app` | Customer-facing app | Booking flow only; access via secure views |

> Change the default password `change_this_password` before use.

### Application Roles

| Role | Key Permissions |
|------|----------------|
| `admin` | All 12 permissions |
| `airline_staff` | flight.create, flight.update, flight.view, seat.manage, booking.view_all, report.view |
| `customer` | flight.view, booking.create, booking.cancel |

### Views

| View | Purpose |
|------|---------|
| `v_passenger_bookings` | Customers see booking details without direct table access |
| `v_flight_availability` | Read-only flight + seat availability for public queries |

### Stored Procedures

#### `sp_cancel_booking(p_booking_id, p_reason, OUT p_result)`

Safely cancels a booking inside a transaction:
1. Locks the booking row with `FOR UPDATE`
2. Validates the current status (rejects if already `cancelled`, `completed`, or `no_show`)
3. Updates booking status and frees the seat in a single atomic operation
4. Returns `'OK: booking cancelled'` or an error string via the `OUT` parameter

```sql
CALL sp_cancel_booking(1, 'Passenger request', @result);
SELECT @result;
```

### Triggers

| Trigger | Event | Action |
|---------|-------|--------|
| `trg_booking_audit_insert` | `AFTER INSERT ON bookings` | Logs new booking details to `audit_logs` as JSON |
| `trg_booking_audit_update` | `AFTER UPDATE ON bookings` | Logs `old_value → new_value` whenever `booking_status` changes |

---

## Project Structure

```
flight-booking-db/
├── schema.sql          # Complete DDL + DML + security setup
└── README.md           # This file
```

---

## Authors

**Group-3 — Advanced Database Systems**

---

## License

This project is for academic purposes. All passwords in seed data are placeholders and must be rotated before any production use.
