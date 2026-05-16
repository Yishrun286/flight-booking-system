# Security Model — Flight Booking System
**Group-3 | Advanced Database Systems**

---

## Overview

Security is enforced at two independent layers: the **MySQL database layer** and the **application layer**. This defense-in-depth approach means a misconfigured application still cannot escalate beyond what the database user is permitted to do.

---

## Layer 1 — Database-Level RBAC (MySQL Users)

Three dedicated MySQL users are created with principle of least privilege:

| MySQL User | Permissions | Used By |
|---|---|---|
| `fb_admin` | SELECT, INSERT, UPDATE on all tables | Admin tools, migrations |
| `fb_staff` | Full access to flights/seats, read-only bookings | Airline staff portal |
| `fb_app` | Booking flow only (via views), no schema access | Customer-facing application |

**Key restrictions:**
- No user has `DELETE` access. Cancellations mark records as `cancelled`, never delete them.
- No user has `DROP` or `ALTER` access in production.
- `fb_app` can only see bookings through the `v_passenger_bookings` view, not the raw table — preventing accidental data leaks.

---

## Layer 2 — Application-Level RBAC (roles + permissions tables)

The `roles`, `permissions`, and `role_permissions` tables provide fine-grained access control that the backend application enforces before executing any query.

**Roles:**
- `admin` — all 12 permissions
- `airline_staff` — flight management, seat control, reporting
- `customer` — flight search, book own ticket, cancel own booking

**Permissions (12 total):**
```
flight.create   flight.update   flight.delete   flight.view
seat.manage
booking.create  booking.cancel  booking.view_all
payment.view    payment.refund
user.manage
report.view
```

---

## Password Hashing Policy

⚠️ **Critical:** The seed data uses `SHA2()` for demonstration only.

SHA-256 is a general-purpose hash — it is fast by design, which makes it unsuitable for passwords. An attacker with a stolen hash can try billions of SHA-256 guesses per second on a GPU.

**Production requirement:** All password hashing must happen in the application layer using:
- **bcrypt** (recommended, cost factor ≥ 12)
- **argon2id** (strongest, preferred for new systems)
- **PBKDF2** (acceptable alternative)

These algorithms are intentionally slow and include a salt, making brute-force attacks impractical.

**What to do:**
1. Never insert plaintext or SHA2 passwords into production.
2. The application receives the plaintext password, hashes it with bcrypt, stores only the hash.
3. On login, the application compares plaintext with the stored hash using the library's verify function.

---

## Session Management

The `user_sessions` table stores session tokens as hashes, never plaintext.

**Session lifecycle:**
1. On login, generate a cryptographically random token (e.g., 32 bytes from `crypto.randomBytes`).
2. Store `SHA2(token, 256)` in `token_hash`. Return the raw token to the client as a cookie/header.
3. On each request, hash the incoming token and look it up in `user_sessions`.
4. Check `expires_at > NOW()` and `revoked = 0` before allowing access.
5. On logout, set `revoked = 1`.

---

## Concurrency & Double-Booking Prevention

The seat booking flow uses `SELECT ... FOR UPDATE` (pessimistic locking):

1. Transaction begins.
2. The target seat row is locked exclusively: `SELECT ... FOR UPDATE`.
3. The application checks `seat_status = 'available'` inside the lock.
4. If available, `UPDATE seats SET seat_status = 'reserved'` and insert the booking.
5. If not available, `ROLLBACK`.

This ensures that even if two users submit a booking for the same seat at the same millisecond, only one transaction will proceed. The other will either wait (blocked) or fail gracefully.

---

## Audit Trail

All booking and payment changes are written to `audit_logs`:

- Trigger `trg_booking_audit_insert` — fires on every new booking.
- Trigger `trg_booking_audit_update` — fires when `booking_status` changes.
- Trigger `trg_payment_audit_update` — fires when `payment_status` changes.
- Trigger `trg_flight_price_change` — fires when `base_price` changes.

**Integrity rules:**
- No application user has `DELETE` on `audit_logs`.
- Rows should never be updated. The log is append-only.
- `old_value` and `new_value` are stored as JSON for flexible querying.

---

## SQL Injection Prevention

All queries executed by the application **must use parameterized statements / prepared statements**.

```python
# Python example — CORRECT
cursor.execute(
    "SELECT * FROM flights WHERE origin_airport_id = %s AND DATE(departure_time) = %s",
    (origin_id, date_str)
)

# WRONG — never do this
cursor.execute(f"SELECT * FROM flights WHERE city = '{user_input}'")
```

The database views (`v_flight_availability`, `v_passenger_bookings`) add an additional layer — the customer app user can only access these views, not the underlying tables directly, limiting the blast radius of any injection vulnerability.
