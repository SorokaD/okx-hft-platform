CREATE MATERIALIZED VIEW IF NOT EXISTS okx_mart.cagg_funding_rate_tick_1m
WITH (timescaledb.continuous) AS
SELECT
  inst_id,
  time_bucket('1 minute', ts_event) AS ts_event,

  -- “последнее наблюдение в минуте”
  last(funding_rate, ts_event)      AS funding_rate_last,

  -- минутная статистика (для прозрачности режима)
  avg(funding_rate)                 AS funding_rate_avg,
  min(funding_rate)                 AS funding_rate_min,
  max(funding_rate)                 AS funding_rate_max,
  stddev_samp(funding_rate)         AS funding_rate_std,
  count(*)                          AS tick_cnt,

  -- мониторинг задержек (pipeline health)
  max(ts_ingest)                    AS ts_ingest_max
FROM okx_core.fact_funding_rate_tick
GROUP BY inst_id, time_bucket('1 minute', ts_event);

-- индекс (Superset любит)
CREATE INDEX IF NOT EXISTS ix_cagg_funding_rate_tick_1m_inst_ts
  ON okx_mart.cagg_funding_rate_tick_1m (inst_id, ts_event DESC);

-- политика обновления (подстрой под себя)
SELECT add_continuous_aggregate_policy(
  'okx_mart.cagg_funding_rate_tick_1m',
  start_offset => INTERVAL '7 days',
  end_offset   => INTERVAL '1 minute',
  schedule_interval => INTERVAL '1 minute'
);









CREATE MATERIALIZED VIEW IF NOT EXISTS okx_mart.cagg_funding_rate_event_1h
WITH (timescaledb.continuous) AS
SELECT
  inst_id,
  time_bucket('1 hour', ts_event) AS ts_event,
  last(funding_rate, ts_event)    AS funding_rate_event,
  max(ts_ingest)                  AS ts_ingest_max
FROM okx_core.fact_funding_rate_event
GROUP BY inst_id, time_bucket('1 hour', ts_event);

CREATE INDEX IF NOT EXISTS ix_cagg_funding_rate_event_1h_inst_ts
  ON okx_mart.cagg_funding_rate_event_1h (inst_id, ts_event DESC);

SELECT add_continuous_aggregate_policy(
  'okx_mart.cagg_funding_rate_event_1h',
  start_offset => INTERVAL '90 days',
  end_offset   => INTERVAL '1 hour',
  schedule_interval => INTERVAL '10 minutes'
);



SELECT
  i.relname AS index_name,
  pg_get_indexdef(i.oid)
FROM pg_class t
JOIN pg_index ix ON t.oid = ix.indrelid
JOIN pg_class i ON i.oid = ix.indexrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
WHERE n.nspname = 'okx_core'
  AND t.relname = 'fact_funding_rate_event'
  AND ix.indisunique = TRUE;


DROP INDEX okx_core.ux_fact_funding_rate_event

ALTER TABLE okx_core.fact_funding_rate_event
ADD CONSTRAINT fact_funding_rate_event_pkey
PRIMARY KEY (inst_id, ts_event);


SELECT create_hypertable(
  'okx_core.fact_funding_rate_event',
  'ts_event',
  migrate_data => TRUE,
  if_not_exists => TRUE
);






CREATE MATERIALIZED VIEW IF NOT EXISTS okx_mart.cagg_funding_rate_event_1h
WITH (timescaledb.continuous) AS
SELECT
  inst_id,
  time_bucket('1 hour', ts_event) AS ts_event,
  last(funding_rate, ts_event)    AS funding_rate_event,
  max(ts_ingest)                  AS ts_ingest_max
FROM okx_core.fact_funding_rate_event
GROUP BY inst_id, time_bucket('1 hour', ts_event);

CREATE INDEX IF NOT EXISTS ix_cagg_funding_rate_event_1h_inst_ts
  ON okx_mart.cagg_funding_rate_event_1h (inst_id, ts_event DESC);

SELECT add_continuous_aggregate_policy(
  'okx_mart.cagg_funding_rate_event_1h',
  start_offset => INTERVAL '90 days',
  end_offset   => INTERVAL '1 hour',
  schedule_interval => INTERVAL '10 minutes'
);



CREATE MATERIALIZED VIEW IF NOT EXISTS okx_mart.mv_funding_rate_box_daily AS
SELECT
  inst_id,
  time_bucket('1 day', ts_event) AS day,

  -- перцентили для боксплота
  percentile_cont(0.05) WITHIN GROUP (ORDER BY funding_rate) AS p05,
  percentile_cont(0.25) WITHIN GROUP (ORDER BY funding_rate) AS p25,
  percentile_cont(0.50) WITHIN GROUP (ORDER BY funding_rate) AS p50,
  percentile_cont(0.75) WITHIN GROUP (ORDER BY funding_rate) AS p75,
  percentile_cont(0.95) WITHIN GROUP (ORDER BY funding_rate) AS p95,

  avg(funding_rate)  AS avg_rate,
  stddev_samp(funding_rate) AS std_rate,
  count(*)           AS tick_cnt
FROM okx_core.fact_funding_rate_tick
GROUP BY inst_id, time_bucket('1 day', ts_event);

CREATE INDEX IF NOT EXISTS ix_mv_funding_rate_box_daily_inst_day
  ON okx_mart.mv_funding_rate_box_daily (inst_id, day DESC);




 
 
 
 
 
 
 
 
 CREATE MATERIALIZED VIEW IF NOT EXISTS okx_mart.mv_funding_rate_health_now AS
WITH last_seen AS (
  SELECT
    inst_id,
    max(ts_ingest) AS last_ts_ingest,
    max(ts_event)  AS last_ts_event
  FROM okx_core.fact_funding_rate_tick
  GROUP BY inst_id
),
lags AS (
  SELECT
    inst_id,
    ts_ingest,
    ts_ingest - lag(ts_ingest)
      OVER (PARTITION BY inst_id ORDER BY ts_ingest) AS ingest_gap
  FROM okx_core.fact_funding_rate_tick
  WHERE ts_ingest >= now() - INTERVAL '1 hour'
),
gaps_1h AS (
  SELECT
    inst_id,
    max(ingest_gap) AS max_ingest_gap_1h,
    avg(ingest_gap) AS avg_ingest_gap_1h
  FROM lags
  GROUP BY inst_id
)
SELECT
  l.inst_id,
  now() AS ts_check,
  l.last_ts_event,
  l.last_ts_ingest,
  now() - l.last_ts_ingest AS ingest_lag_now,
  g.max_ingest_gap_1h,
  g.avg_ingest_gap_1h
FROM last_seen l
LEFT JOIN gaps_1h g USING (inst_id);


CREATE INDEX IF NOT EXISTS ix_mv_funding_rate_health_now_inst
  ON okx_mart.mv_funding_rate_health_now (inst_id);

REFRESH MATERIALIZED VIEW okx_mart.mv_funding_rate_health_now;















