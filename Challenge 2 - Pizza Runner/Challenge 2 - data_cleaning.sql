-- database: pizza_runner.db

/*DATA CLEANING*/

------- runner_orders -------
-- cancelled orders --
UPDATE runner_orders
SET pickup_time = NULL, distance = NULL, duration = NULL
WHERE distance = 'null';

-- cleaning distance --
ALTER TABLE runner_orders
RENAME distance TO distance_bis;
ALTER TABLE runner_orders
ADD COLUMN distance INTEGER;
UPDATE runner_orders
SET distance = REPLACE(distance_bis,'km','');
ALTER TABLE runner_orders
DROP COLUMN distance_bis;

-- cleaning duration --
ALTER TABLE runner_orders
RENAME duration TO duration_bis;
ALTER TABLE runner_orders
ADD COLUMN duration INTEGER;
UPDATE runner_orders
SET duration = CAST(SUBSTRING(duration_bis,0,3) AS INTEGER);
ALTER TABLE runner_orders
DROP COLUMN duration_bis;

-- cancellation --
UPDATE runner_orders
SET cancellation = NULL
WHERE cancellation NOT LIKE '%Cancellation%';

------- customer_orders -------
UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions LIKE '' OR exclusions = 'null';

UPDATE customer_orders
SET extras = NULL
WHERE extras LIKE '' OR extras = 'null';
