# PITR Incident Record

## Verified recovery inputs

- PostgreSQL major version: 16
- Base backup: `base_000000010000000000000006`
- Rows present in the base dataset: 5
- Rows present immediately before the incident: 6
- Named restore point: `before_accidental_delete`
- Restore-point LSN: `0/8000090`
- Restore-point WAL: `000000010000000000000008`
- Restore-point time: `2026-09-23 18:19:33.358083+00`

## Simulated incident

The script `sql/999_accidental_delete.sql` committed an unscoped deletion:

```sql
DELETE FROM lab.orders;
```

- Rows remaining on the damaged primary: 0
- WAL containing the committed damage: `000000010000000000000009`
- Final archiver status: 10 archived, 0 failed
- Destructive transaction time: `2026-09-23 18:19:38.662412+00`

## Verified recovery result

On 2026-10-30, the existing recovery volume was copied to a temporary Docker volume. That copy was mounted in a network-disabled container with PostgreSQL archive recovery disabled, and queried read-only. The result contained exactly six rows: `LAB-001`, `LAB-002`, `LAB-003`, `LAB-004`, `LAB-005`, and `LAB-006`. The committed deletion was not replayed.

The recovered data directory's PostgreSQL log also records recovery stopping before commit of the destructive transaction, followed by archive recovery completing and PostgreSQL becoming ready. The result above was checked from the isolated copy; no cloud credentials were used for the verification.
