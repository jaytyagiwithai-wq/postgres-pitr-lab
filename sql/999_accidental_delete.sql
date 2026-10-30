-- Incident simulation: a junior intended to delete one test order but
-- accidentally omitted the WHERE clause and committed the transaction.
BEGIN;

DELETE FROM lab.orders;

COMMIT;
