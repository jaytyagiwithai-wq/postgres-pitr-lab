CREATE SCHEMA IF NOT EXISTS lab;

CREATE TABLE IF NOT EXISTS lab.orders (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_reference TEXT NOT NULL UNIQUE,
    customer_name TEXT NOT NULL,
    amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
    status TEXT NOT NULL CHECK (
        status IN ('received', 'processing', 'dispatched')
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO lab.orders (
    order_reference,
    customer_name,
    amount_cents,
    status
)
VALUES
    ('LAB-001', 'Akira', 2500, 'received'),
    ('LAB-002', 'Mia', 4800, 'processing'),
    ('LAB-003', 'Noah', 1500, 'received'),
    ('LAB-004', 'Yuki', 7200, 'dispatched'),
    ('LAB-005', 'Emma', 3100, 'processing')
ON CONFLICT (order_reference) DO NOTHING;
