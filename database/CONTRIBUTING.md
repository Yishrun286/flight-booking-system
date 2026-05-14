# Contributing Guide — Flight Booking System
**Group-3 | Advanced Database Systems**

---

## Branch Naming Convention

| Type | Pattern | Example |
|---|---|---|
| Feature | `feat/<module>` | `feat/stored-procedures` |
| Bug fix | `fix/<what>` | `fix/seat-status-on-cancel` |
| Documentation | `docs/<topic>` | `docs/viva-questions` |
| Configuration | `chore/<what>` | `chore/gitignore-update` |

## Commit Message Format

```
type(module): short description

Examples:
feat(schema): add flight_price_history table
fix(trigger): guard against price change when price is unchanged
docs(queries): add EXPLAIN output for Q1 flight search
test(concurrency): add double-booking prevention test case
chore(backup): add 7-day rotation to backup.sh
```

## Pull Request Rules

1. One PR per module/feature.
2. Assign at least one reviewer from your team.
3. All SQL files must run without errors on MySQL 8.0 before opening a PR.
4. Never force-push to `main`.
5. Never delete a table or stored procedure without team agreement.

## Running SQL Files

```bash
# Full setup (recommended)
bash scripts/setup.sh

# Individual file
mysql -u root -p flight_booking < database/triggers/005_triggers.sql
```

## Code Style

- Use UPPERCASE for SQL keywords: `SELECT`, `FROM`, `WHERE`, `JOIN`.
- Align column definitions vertically for readability.
- Add a comment block header to every SQL file.
- Use `IF NOT EXISTS` / `IF EXISTS` on all CREATE and DROP statements.
