# dbops-project
Исходный репозиторий для выполнения проекта дисциплины "DBOps"

# Права для роли cicd
CREATE ROLE cicd
LOGIN
PASSWORD ‘cicd’
NOSUPERUSER
NOCREATEDB
NOCREATEROLE
NOINHERIT;

REVOKE CONNECT ON DATABASE store FROM PUBLIC;

GRANT CONNECT ON DATABASE store TO cicd;

GRANT USAGE, CREATE ON SCHEMA public TO cicd;

GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES
ON ALL TABLES IN SCHEMA public
TO cicd;

GRANT USAGE, SELECT, UPDATE
ON ALL SEQUENCES IN SCHEMA public
TO cicd;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES
ON TABLES TO cicd;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
GRANT USAGE, SELECT, UPDATE
ON SEQUENCES TO cicd;

# Запрос количества проданных сосисок
SELECT o.date_created, SUM(op.quantity)
FROM orders o
JOIN order_product op ON o.id = op.order_id
WHERE o.status = 'shipped' AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created
ORDER BY o.date_created ASC;
