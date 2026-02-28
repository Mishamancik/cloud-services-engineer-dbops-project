# Проектная работа по DBOps

### Создание пользователя для cicd
```sql
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
```

---
### Сколько было продано сосисок
Запрос по дням за последнюю неделю
```sql
SELECT o.date_created, SUM(op.quantity)
FROM orders o
JOIN order_product op ON o.id = op.order_id
WHERE o.status = 'shipped' AND o.date_created > NOW() - INTERVAL '7 DAY'
GROUP BY o.date_created
ORDER BY o.date_created ASC;
```

Результат выполнения запроса
```
 date_created |  sum   
--------------+--------
 2026-02-22   | 938412
 2026-02-23   | 935229
 2026-02-24   | 943272
 2026-02-25   | 933909
 2026-02-26   | 942663
 2026-02-27   | 947385
 2026-02-28   | 941473
(7 rows)
```

---
### Анализ времени выполнения запросов
| Index | Time, ms | Time |
|----------------|:---------:|:----------------:|
| no index | 5743.678 | (00:05.744) |
| order_product_order_id_idx | 1689.298 | (00:01.689) |
| orders_status_date_idx + order_product_order_id_idx | 1274.239 | (00:01.274) |

---
### Результаты EXPLAIN ANALYZE
#### no index
```
                                                                              QUERY PLAN                                                                              
----------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=266215.13..266237.93 rows=90 width=12) (actual time=5660.688..5665.679 rows=7 loops=1)
   Group Key: o.date_created
   ->  Gather Merge  (cost=266215.13..266236.13 rows=180 width=12) (actual time=5660.659..5665.648 rows=21 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=265215.11..265215.33 rows=90 width=12) (actual time=5635.214..5635.216 rows=7 loops=3)
               Sort Key: o.date_created
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=265211.28..265212.18 rows=90 width=12) (actual time=5635.185..5635.188 rows=7 loops=3)
                     Group Key: o.date_created
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Parallel Hash Join  (cost=148374.07..264672.56 rows=107745 width=8) (actual time=2585.241..5620.762 rows=86046 loops=3)
                           Hash Cond: (op.order_id = o.id)
                           ->  Parallel Seq Scan on order_product op  (cost=0.00..105361.13 rows=4166613 width=12) (actual time=0.538..2362.063 rows=3333333 loops=3)
                           ->  Parallel Hash  (cost=147027.26..147027.26 rows=107745 width=12) (actual time=2583.975..2583.975 rows=86046 loops=3)
                                 Buckets: 262144  Batches: 1  Memory Usage: 14208kB
                                 ->  Parallel Seq Scan on orders o  (cost=0.00..147027.26 rows=107745 width=12) (actual time=12.146..2549.301 rows=86046 loops=3)
                                       Filter: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                                       Rows Removed by Filter: 3247288
 Planning Time: 8.889 ms
 JIT:
   Functions: 54
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 2.079 ms, Inlining 0.000 ms, Optimization 1.074 ms, Emission 35.412 ms, Total 38.566 ms
 Execution Time: 5681.932 ms
(29 rows)


```


#### order_product_order_id_idx
```
                                                                             QUERY PLAN                                                                              
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=266216.92..266239.72 rows=90 width=12) (actual time=1969.613..1973.393 rows=7 loops=1)
   Group Key: o.date_created
   ->  Gather Merge  (cost=266216.92..266237.92 rows=180 width=12) (actual time=1969.588..1973.366 rows=21 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=265216.89..265217.12 rows=90 width=12) (actual time=1942.341..1942.343 rows=7 loops=3)
               Sort Key: o.date_created
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=265213.07..265213.97 rows=90 width=12) (actual time=1942.319..1942.322 rows=7 loops=3)
                     Group Key: o.date_created
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Parallel Hash Join  (cost=148375.17..264674.34 rows=107747 width=8) (actual time=678.076..1926.271 rows=86046 loops=3)
                           Hash Cond: (op.order_id = o.id)
                           ->  Parallel Seq Scan on order_product op  (cost=0.00..105361.67 rows=4166667 width=12) (actual time=0.367..340.963 rows=3333333 loops=3)
                           ->  Parallel Hash  (cost=147028.33..147028.33 rows=107747 width=12) (actual time=676.607..676.608 rows=86046 loops=3)
                                 Buckets: 262144  Batches: 1  Memory Usage: 14208kB
                                 ->  Parallel Seq Scan on orders o  (cost=0.00..147028.33 rows=107747 width=12) (actual time=11.476..644.576 rows=86046 loops=3)
                                       Filter: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                                       Rows Removed by Filter: 3247288
 Planning Time: 0.184 ms
 JIT:
   Functions: 54
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 4.014 ms, Inlining 0.000 ms, Optimization 0.936 ms, Emission 33.525 ms, Total 38.475 ms
 Execution Time: 1974.183 ms
(29 rows)


```


#### orders_status_date_idx + order_product_order_id_idx
```
                                                                                    QUERY PLAN                                                                                    
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Finalize GroupAggregate  (cost=188581.53..188604.33 rows=90 width=12) (actual time=1548.385..1555.118 rows=7 loops=1)
   Group Key: o.date_created
   ->  Gather Merge  (cost=188581.53..188602.53 rows=180 width=12) (actual time=1548.372..1555.103 rows=21 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Sort  (cost=187581.50..187581.73 rows=90 width=12) (actual time=1521.685..1521.688 rows=7 loops=3)
               Sort Key: o.date_created
               Sort Method: quicksort  Memory: 25kB
               Worker 0:  Sort Method: quicksort  Memory: 25kB
               Worker 1:  Sort Method: quicksort  Memory: 25kB
               ->  Partial HashAggregate  (cost=187577.68..187578.58 rows=90 width=12) (actual time=1521.658..1521.662 rows=7 loops=3)
                     Group Key: o.date_created
                     Batches: 1  Memory Usage: 24kB
                     Worker 0:  Batches: 1  Memory Usage: 24kB
                     Worker 1:  Batches: 1  Memory Usage: 24kB
                     ->  Parallel Hash Join  (cost=70739.78..187038.95 rows=107747 width=8) (actual time=265.594..1501.885 rows=86046 loops=3)
                           Hash Cond: (op.order_id = o.id)
                           ->  Parallel Seq Scan on order_product op  (cost=0.00..105361.67 rows=4166667 width=12) (actual time=0.022..354.079 rows=3333333 loops=3)
                           ->  Parallel Hash  (cost=69392.94..69392.94 rows=107747 width=12) (actual time=264.135..264.136 rows=86046 loops=3)
                                 Buckets: 262144  Batches: 1  Memory Usage: 14240kB
                                 ->  Parallel Bitmap Heap Scan on orders o  (cost=3543.01..69392.94 rows=107747 width=12) (actual time=26.141..227.679 rows=86046 loops=3)
                                       Recheck Cond: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
                                       Heap Blocks: exact=19828
                                       ->  Bitmap Index Scan on orders_status_date_idx  (cost=0.00..3478.36 rows=258592 width=0) (actual time=31.109..31.109 rows=258137 loops=1)
                                             Index Cond: (((status)::text = 'shipped'::text) AND (date_created > (now() - '7 days'::interval)))
 Planning Time: 0.313 ms
 JIT:
   Functions: 57
   Options: Inlining false, Optimization false, Expressions true, Deforming true
   Timing: Generation 3.869 ms, Inlining 0.000 ms, Optimization 1.046 ms, Emission 32.706 ms, Total 37.621 ms
 Execution Time: 1555.801 ms
(31 rows)


```
