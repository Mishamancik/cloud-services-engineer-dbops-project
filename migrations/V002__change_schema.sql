ALTER TABLE orders
ADD COLUMN date_created date DEFAULT CURRENT_DATE;

ALTER TABLE product
ADD COLUMN price double precision;

UPDATE orders o
SET date_created = od.date_created
FROM orders_date od
WHERE o.id = od.order_id;

UPDATE product p
SET price = pi.price
FROM product_info pi
WHERE p.id = pi.product_id;

ALTER TABLE orders
ADD PRIMARY KEY (id);

ALTER TABLE product
ADD PRIMARY KEY (id);

ALTER TABLE order_product
ADD CONSTRAINT order_product_order_fk
FOREIGN KEY (order_id)
REFERENCES orders (id)
ON DELETE CASCADE;

ALTER TABLE order_product
ADD CONSTRAINT order_product_product_fk
FOREIGN KEY (product_id)
REFERENCES product (id)
ON DELETE CASCADE;

DROP TABLE orders_date;

DROP TABLE product_info;
