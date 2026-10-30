INSERT INTO lab.orders (
    order_reference,
    customer_name,
    amount_cents,
    status
)
VALUES (
    'LAB-006',
    'Sora',
    9900,
    'received'
)
ON CONFLICT (order_reference) DO NOTHING;
