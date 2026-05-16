# Team Contribution Plan — Flight Booking System
**Group-3 | Advanced Database Systems | 10 Members**

---

## Member Roles & Assignments

| # | Member | Role | Module | Branch |
|---|---|---|---|---|
| 1 | Member 1 | Database Architect | Schema design, normalization, ER diagram | `feat/schema-design` |
| 2 | Member 2 | Security Engineer | RBAC tables, MySQL grants, session management | `feat/security-rbac` |
| 3 | Member 3 | Query Optimizer | 5 optimized queries, EXPLAIN analysis | `feat/query-optimization` |
| 4 | Member 4 | Stored Procedure Dev | sp_cancel_booking, sp_confirm_booking, sp_book_seat | `feat/stored-procedures` |
| 5 | Member 5 | Trigger Developer | Audit triggers, price history trigger | `feat/triggers-audit` |
| 6 | Member 6 | Seed Data Engineer | Reference data, sample flights, passengers | `feat/seed-data` |
| 7 | Member 7 | View Developer | 5 reporting views, occupancy, revenue | `feat/views-reporting` |
| 8 | Member 8 | Testing Lead | Test cases table, concurrency tests | `feat/testing` |
| 9 | Member 9 | Documentation Lead | SRS, QUERIES.md, SECURITY.md, VIVA_QA.md | `feat/documentation` |
| 10 | Member 10 | DevOps & Setup | Backup script, setup script, CI workflow | `feat/devops-scripts` |

---

## Git Workflow

### 1. Initial Setup
```bash
git clone https://github.com/your-group/flight-booking-system.git
cd flight-booking-system
git checkout -b feat/your-module-name
```

### 2. Daily Workflow
```bash
git add .
git commit -m "feat(module): description of what you did"
git push origin feat/your-module-name
```

### 3. Merging to Main
- Open a Pull Request from your branch to `main`
- Request review from one other team member
- Merge only after approval

### Branch Protection Rules
- `main` branch: no direct push allowed
- All merges via Pull Request
- At least 1 review required

---

## 50+ Realistic Commit Messages

### Member 1 — Schema Design
```
feat(schema): add initial flight_booking database with CREATE DATABASE
feat(schema): create regions and airports tables with IATA support
feat(schema): add airlines and aircraft tables with registration codes
feat(schema): create flights table with status ENUM and time constraints
feat(schema): add CHECK constraint to enforce arrival_time > departure_time
feat(schema): create seats table with per-flight seat inventory
feat(schema): add composite index idx_flights_route_date for search performance
feat(schema): create bookings table with full lifecycle status ENUM
fix(schema): correct uq_seat_booking constraint documentation comment
docs(schema): add TABLE COMMENT explaining data_partitions purpose
```

### Member 2 — Security & RBAC
```
feat(security): create roles, permissions, and role_permissions tables
feat(security): seed admin, airline_staff, and customer roles
feat(security): assign all 12 permissions to admin role
feat(security): configure airline_staff permissions for flight management
feat(security): create users table with FK to passengers and roles
feat(security): create user_sessions table with token_hash and expiry
feat(security): add MySQL user fb_admin with least-privilege grants
feat(security): create fb_staff MySQL user with staff-level grants
feat(security): create fb_app MySQL user restricted to booking flow only
docs(security): document SHA2 seed password limitation and bcrypt requirement
```

### Member 3 — Query Optimization
```
feat(queries): write Q1 flight search using composite index on route+date
feat(queries): write Q2 seat availability query using idx_seats_status
feat(queries): write Q3 passenger booking history with ordered results
feat(queries): write Q4 daily occupancy rate with NULLIF division guard
feat(queries): write Q5 revenue report with COALESCE for null safety
perf(queries): add EXPLAIN annotations for all 5 optimized queries
fix(queries): replace NULL revenue with COALESCE in Q5 for flights with no bookings
docs(queries): document expected EXPLAIN output for Q1 and Q2
```

### Member 4 — Stored Procedures
```
feat(proc): create sp_cancel_booking with transaction and FOR UPDATE lock
feat(proc): add rollback on invalid status in sp_cancel_booking
feat(proc): create sp_confirm_booking with payment status validation
feat(proc): add error handling for missing booking in sp_confirm_booking
feat(proc): create sp_book_seat full booking flow procedure
feat(proc): generate unique booking_ref using MD5 in sp_book_seat
feat(proc): add pending payment insert inside sp_book_seat transaction
fix(proc): handle case where booking_id not found in sp_cancel_booking
```

### Member 5 — Triggers
```
feat(trigger): create trg_booking_audit_insert for new booking logging
feat(trigger): create trg_booking_audit_update on booking status change
feat(trigger): add trg_flight_price_change to populate flight_price_history
feat(trigger): add flight status change logging in trg_flight_price_change
feat(trigger): create trg_payment_audit_update for payment transitions
fix(trigger): guard against unnecessary audit rows when price unchanged
docs(trigger): add verification queries for all triggers in comments
```

### Member 6 — Seed Data
```
feat(seed): insert seat_classes: First, Business, Economy
feat(seed): insert payment_methods: Telebirr, Card, Bank Transfer, M-Pesa
feat(seed): add regions and IATA-coded airports for Ethiopia and Kenya
feat(seed): insert Ethiopian Airlines and Kenya Airways with IATA codes
feat(seed): add aircraft registrations for Boeing 737-800 and Airbus A320
feat(seed): insert 8 realistic flight schedules across routes
feat(seed): add seats for flights with realistic status distribution
feat(seed): insert 5 sample passengers with local Ethiopian phone numbers
feat(seed): create user accounts linked to passengers with role assignments
feat(seed): add sample bookings and payments in various states
```

### Member 7 — Views
```
feat(view): create v_passenger_bookings joining 7 tables for booking detail
feat(view): create v_flight_availability with per-class seat count columns
feat(view): add duration_minutes computed column to v_flight_availability
feat(view): create v_revenue_report with gross, refunds, and net columns
feat(view): create v_occupancy_report with occupancy_pct calculation
feat(view): create v_audit_summary joining audit_logs with usernames
fix(view): use COALESCE in v_revenue_report to handle flights with no bookings
```

### Member 8 — Testing
```
test: add TC-01 schema integrity tests for all constraints
test: add TC-02 booking flow test cases for sp_book_seat
test: add TC-03 concurrency double-booking test procedure
test: add TC-04 trigger verification test cases
test: add TC-05 RBAC permission test cases for MySQL users
test: add TC-06 view correctness test cases
test: add TC-07 data validation constraint tests
test: add TC-08 query performance EXPLAIN test cases
docs(test): add bug tracking table with resolved issues
```

### Member 9 — Documentation
```
docs: create README.md with full project overview and setup guide
docs: add DATABASE.md schema table inventory with design decisions
docs: write QUERIES.md with EXPLAIN analysis for all 5 queries
docs: create SECURITY.md covering two-layer RBAC model
docs: write VIVA_QA.md with 20 questions across 7 categories
docs: add normalization explanation in DATABASE.md
docs: document data_partitions table purpose and future use
docs: add LinkedIn and CV project descriptions to README
```

### Member 10 — DevOps
```
chore: create project folder structure with all subdirectories
feat(scripts): write setup.sh one-command database initialization script
feat(backup): create backup.sh with dated MySQL dump automation
feat(ci): add GitHub Actions workflow for SQL lint on push
chore: add .gitignore for MySQL dumps, credentials, and OS files
chore: add db.example.env environment variable template
docs: write CONTRIBUTING.md with PR workflow and branch naming guide
chore: add MIT LICENSE file
chore: add data_partitions seed entries for logical shard registry
docs: add release notes and version naming convention to README
```

---

## Pull Request Template

When opening a PR, use this description:

```
## What this PR does
Brief description of the changes.

## Module
Which module (schema / queries / triggers / etc.)

## Files changed
- database/migrations/001_initial_schema.sql
- docs/QUERIES.md

## Test steps
How to verify the changes work.

## Checklist
- [ ] SQL runs without errors on MySQL 8.0
- [ ] No existing tables/procedures removed
- [ ] Changes documented
```

---

## Weekly Contribution Plan

| Week | Activity |
|---|---|
| Week 1 | Schema design (M1), security planning (M2), project structure (M10) |
| Week 2 | Query writing (M3), stored procedures (M4), seed data (M6) |
| Week 3 | Triggers (M5), views (M7), testing framework (M8) |
| Week 4 | Documentation (M9), DevOps scripts (M10), final review + merges |
