# Viva Questions & Answers — Flight Booking System
**Group-3 | Advanced Database Systems**

---

## Section 1: Schema & Normalization

**Q: Is your schema in Third Normal Form (3NF)? Prove it.**

Yes. 1NF: all attributes are atomic, no repeating groups. 2NF: all non-key attributes depend on the full primary key — e.g., in `flights`, `departure_time` depends on `flight_id`, not just part of it. 3NF: no transitive dependencies — `city` is stored in `airports`, not duplicated inside `flights`. The route is represented by two foreign keys (`origin_airport_id`, `dest_airport_id`) that point to `airports`.

---

**Q: Why did you store city in airports instead of flights?**

Storing city in flights would be a transitive dependency: `city` depends on `airport_id`, not on `flight_id`. That violates 3NF. If an airport city name changed, we would need to update every flight row, risking inconsistency. With the normalized design, one `UPDATE airports` fixes it everywhere.

---

**Q: Why use ENUM for booking_status instead of a separate status table?**

ENUM enforces a closed set of valid values at the database engine level with zero application logic required. For a small, stable set of states like booking lifecycle, ENUM is appropriate and more efficient than a JOIN to a lookup table. We used ENUM for `booking_status`, `flight status`, `seat_status`, and `payment_status` — all of which have fixed, well-known states that will not change frequently.

---

## Section 2: Indexing & Query Optimization

**Q: Explain your composite index on flights.**

`idx_flights_route_date (origin_airport_id, dest_airport_id, departure_time)` — this index directly matches Q1, our most-used query: flight search by origin, destination, and date. MySQL can satisfy all three filter conditions from this one index, range-scanning on `departure_time` after pinpointing the route. Without it, MySQL would do a full table scan on every flight search.

---

**Q: Why not just index every column?**

Indexes speed up reads but slow down writes. Every INSERT, UPDATE, and DELETE must update all relevant indexes. Over-indexing on a high-write table like `bookings` would hurt insert performance. We index only columns that appear in WHERE clauses of frequent queries, join keys, and columns used in ORDER BY.

---

**Q: What does EXPLAIN show and why did you use it?**

`EXPLAIN` shows MySQL's query execution plan — which indexes it selects, estimated row counts, and join strategy. We use it to verify that our indexes are actually being used. `type = ref` or `type = range` means index access (fast). `type = ALL` means full table scan (slow). After adding `idx_flights_route_date`, Q1 went from `type = ALL` to `type = range`.

---

## Section 3: Transactions & Concurrency

**Q: How do you prevent double-booking?**

Using a pessimistic locking pattern with `SELECT ... FOR UPDATE` inside a transaction. When a passenger attempts to book seat 10A on flight 1, we:
1. `START TRANSACTION`
2. `SELECT seat_id, seat_status FROM seats WHERE flight_id=1 AND seat_number='10A' FOR UPDATE` — this acquires an exclusive row lock
3. Check `seat_status = 'available'` inside the transaction
4. If available, update status to `reserved` and insert the booking
5. `COMMIT`

If Session B tries to book the same seat while Session A holds the lock, B will block until A commits. After A commits, B re-reads the seat and finds `seat_status = 'reserved'` — it then rolls back with an error message.

---

**Q: What is the difference between COMMIT and ROLLBACK?**

`COMMIT` makes all changes in the current transaction permanent and visible to other sessions. `ROLLBACK` undoes all changes since the last `START TRANSACTION`, leaving the database in the state it was before the transaction began. In our `sp_cancel_booking`, if the booking is already cancelled, we `ROLLBACK` to undo the `FOR UPDATE` lock without making any changes.

---

**Q: What is ACID and does your system satisfy it?**

- **Atomicity:** Each stored procedure wraps its operations in a transaction — either all steps succeed (COMMIT) or none do (ROLLBACK). ✓
- **Consistency:** Foreign key constraints, CHECK constraints, and ENUM values enforce valid state at all times. ✓
- **Isolation:** `SELECT ... FOR UPDATE` and InnoDB's row-level locking prevent dirty reads and lost updates during concurrent bookings. ✓
- **Durability:** InnoDB writes to its redo log before confirming a commit. Committed transactions survive a server crash. ✓

---

## Section 4: Security & RBAC

**Q: Explain your two-layer security model.**

Layer 1 is MySQL-level: three dedicated database users (`fb_admin`, `fb_staff`, `fb_app`) each with minimum necessary privileges. `fb_app` can only access specific views and tables needed for the booking flow. Layer 2 is application-level: the `roles`, `permissions`, and `role_permissions` tables define 12 granular permissions. The backend checks these before executing any operation.

---

**Q: Why is SHA2 not suitable for password storage?**

SHA2 is a general-purpose cryptographic hash designed to be fast. Password hashing needs the opposite — it must be intentionally slow to make brute-force attacks impractical. bcrypt, which we recommend for production, includes a configurable cost factor and a random salt per hash. It is designed specifically for passwords. Our seed data uses SHA2 for demonstration only; this is clearly documented as unsafe for production.

---

**Q: What is SQL injection and how does your design prevent it?**

SQL injection is an attack where user-supplied input is interpreted as SQL code. For example, entering `'; DROP TABLE bookings; --` into an unprotected form. Prevention: all application queries must use parameterized statements (prepared statements), where user input is passed as a separate parameter, never concatenated into the SQL string. Additionally, `fb_app` only has access to specific views and tables, limiting what an injected query could reach even if parameterization failed.

---

## Section 5: Triggers & Stored Procedures

**Q: What triggers did you implement and why?**

Four triggers:
1. `trg_booking_audit_insert` — logs every new booking to `audit_logs` automatically
2. `trg_booking_audit_update` — logs every booking status change with old/new JSON values
3. `trg_flight_price_change` — populates `flight_price_history` whenever `base_price` changes, and logs the change to audit
4. `trg_payment_audit_update` — logs payment status transitions

Triggers are chosen here because the audit requirement must be enforced regardless of which application or script modifies the data — a trigger fires at the database level unconditionally.

---

**Q: Why use stored procedures for booking and cancellation?**

Stored procedures encapsulate complex multi-step business logic at the database layer. They ensure:
- The same locking and validation logic runs regardless of which application calls them
- The transaction is managed consistently
- The application code is simpler — it calls `CALL sp_cancel_booking(...)` with two parameters
- No chance of a developer forgetting to release the seat when cancelling a booking

---

## Section 6: Views

**Q: What is the difference between a view and a table?**

A table physically stores data. A view is a named, stored SELECT query — it has no data of its own. When queried, the database executes the underlying SELECT and returns results. Views provide: security (expose only certain columns/rows), simplicity (pre-built joins the application can query with a simple SELECT), and abstraction (the underlying schema can change without breaking the view's interface).

---

**Q: Why did you create v_passenger_bookings as a view instead of a direct query?**

It joins 7 tables to return meaningful booking information. Putting this join inside a view means the application executes `SELECT * FROM v_passenger_bookings WHERE passenger_id = ?` — one simple line — instead of writing the full 7-table join each time. It also means if we add a column to the join in the future, we update the view definition in one place.

---

## Section 7: General

**Q: What would you improve if you had more time?**

1. Replace SHA2 seed passwords with bcrypt hashed from the application layer
2. Add MySQL table partitioning on `bookings` by year for long-term scalability
3. Implement a `notifications` table with email/SMS triggers
4. Wire the `data_partitions` table to a real sharding implementation
5. Add a `CHECK-IN` stage to the booking status lifecycle
6. Add Redis caching for the `v_flight_availability` view to reduce DB load during peak search traffic

---

**Q: How many tables does your database have?**

17 tables: `regions`, `airports`, `airlines`, `aircraft`, `seat_classes`, `flights`, `seats`, `passengers`, `bookings`, `payment_methods`, `payments`, `roles`, `permissions`, `role_permissions`, `users`, `audit_logs`, `user_sessions`, `flight_price_history`, `data_partitions`.
