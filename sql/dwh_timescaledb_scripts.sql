-- 1) Расширение TimescaleDB (нужно один раз на БД)
CREATE EXTENSION IF NOT EXISTS timescaledb;
-- 2) Схемы DWH
CREATE SCHEMA IF NOT EXISTS okx_raw;   -- как прилетело с WS/REST, без украшений
CREATE SCHEMA IF NOT EXISTS okx_core;  -- нормализация, ключи, дедупликация
CREATE SCHEMA IF NOT EXISTS okx_mart;  -- агрегаты и фичи (1s/100ms бары, OFI, spreads, imbalance и т.п.)
CREATE SCHEMA IF NOT EXISTS okx_ref;   -- справочники (инструменты, лотность, мэппинги, календари)
CREATE SCHEMA IF NOT EXISTS okx_feat;  -- витрины/фичи для обучения (опционально)
-- 3) (опц.) Назначим владельца всех схем текущему юзеру (замени на своего при желании)
ALTER SCHEMA okx_raw  OWNER TO admin;
ALTER SCHEMA okx_core OWNER TO admin;
ALTER SCHEMA okx_mart OWNER TO admin;
ALTER SCHEMA okx_ref  OWNER TO admin;
ALTER SCHEMA okx_feat OWNER TO admin;
-- 4) (опц.) Удобный search_path для этой БД
ALTER DATABASE okx_hft SET search_path = public, okx_raw, okx_core, okx_ref, okx_mart, okx_feat;

-- Для каждой большой таблицы (trades, tickers, orderbook_updates, …) должна быть hypertable по времени
-- raw
SELECT create_hypertable('okx_raw.trades', 'ts_event_ms', migrate_data => true);
SELECT create_hypertable('okx_raw.tickers', 'ts_event_ms', migrate_data => true);
SELECT create_hypertable('okx_raw.orderbook_updates', 'ts_event_ms', migrate_data => true);
SELECT create_hypertable('okx_raw.funding_rates', 'ts_event_ms', migrate_data => true);
SELECT create_hypertable('okx_raw.mark_prices', 'ts_event_ms', migrate_data => true);
SELECT create_hypertable('okx_raw.open_interest', 'ts_event_ms', migrate_data => true);
SELECT create_hypertable('okx_raw.orderbook_snapshots', 'ts_event_ms', migrate_data => true);
SELECT create_hypertable('okx_raw.index_tickers', 'ts_event_ms', migrate_data => true);
-- core
SELECT create_hypertable('okx_core.fact_funding_rate_event', 'ts_event', migrate_data => true);
SELECT create_hypertable('okx_core.fact_funding_rate_tick', 'ts_event', migrate_data => true);
SELECT create_hypertable('okx_core.fact_index_tick', 'ts_event', migrate_data => true);
SELECT create_hypertable('okx_core.fact_mark_price_tick', 'ts_event', migrate_data => true);
SELECT create_hypertable('okx_core.fact_open_interest_tick', 'ts_event', migrate_data => true);
SELECT create_hypertable('okx_core.fact_orderbook_snapshot', 'ts_event', migrate_data => true); --
SELECT create_hypertable('okx_core.fact_orderbook_update', 'ts_event', migrate_data => true);
SELECT create_hypertable('okx_core.fact_ticker_tick', 'ts_event', migrate_data => true);
SELECT create_hypertable('okx_core.fact_trades_tick', 'ts_event', migrate_data => true);

-- Включить компрессию для старых чанков
-- raw
ALTER table okx_raw.funding_rates
  SET (
    timescaledb.compress = true,
    timescaledb.compress_segmentby = 'instid',            -- по инструменту
    timescaledb.compress_orderby  = 'ts_event_ms'
  );
ALTER table okx_raw.index_tickers
  SET (
    timescaledb.compress = true,
    timescaledb.compress_segmentby = 'instid',            -- по инструменту
    timescaledb.compress_orderby  = 'ts_event_ms'
  );
 ALTER TABLE okx_raw.mark_prices
  SET (
    timescaledb.compress = true,
    timescaledb.compress_segmentby = 'instid',            -- по инструменту
    timescaledb.compress_orderby  = 'ts_event_ms'
  );
 ALTER TABLE okx_raw.open_interest
  SET (
    timescaledb.compress = true,
    timescaledb.compress_segmentby = 'instid',            -- по инструменту
    timescaledb.compress_orderby  = 'ts_event_ms'
  );
 ALTER TABLE okx_raw.orderbook_snapshots
  SET (
    timescaledb.compress = true,
    timescaledb.compress_segmentby = 'instid',            -- по инструменту
    timescaledb.compress_orderby  = 'ts_event_ms'
  );
 ALTER TABLE okx_raw.orderbook_updates
  SET (
    timescaledb.compress = true,
    timescaledb.compress_segmentby = 'instid',            -- по инструменту
    timescaledb.compress_orderby  = 'ts_event_ms'
  );
 ALTER TABLE okx_raw.tickers
  SET (
    timescaledb.compress = true,
    timescaledb.compress_segmentby = 'instid',            -- по инструменту
    timescaledb.compress_orderby  = 'ts_event_ms'
  );
 ALTER TABLE okx_raw.trades
  SET (
    timescaledb.compress = true,
    timescaledb.compress_segmentby = 'instid',            -- по инструменту
    timescaledb.compress_orderby  = 'ts_event_ms'
  );
-- core
SET statement_timeout = 0;
-- funding_rate_event
ALTER TABLE okx_core.fact_funding_rate_event
SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'inst_id',
  timescaledb.compress_orderby   = 'ts_event DESC'
);
SELECT add_compression_policy('okx_core.fact_funding_rate_event', INTERVAL '6 hours');

-- funding_rate_tick
ALTER TABLE okx_core.fact_funding_rate_tick
SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'inst_id',
  timescaledb.compress_orderby   = 'ts_event DESC'
);
SELECT add_compression_policy('okx_core.fact_funding_rate_tick', INTERVAL '6 hours');

-- index_tick
ALTER TABLE okx_core.fact_index_tick
SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'inst_id',
  timescaledb.compress_orderby   = 'ts_event DESC'
);
SELECT add_compression_policy('okx_core.fact_index_tick', INTERVAL '6 hours');

-- mark_price_tick
ALTER TABLE okx_core.fact_mark_price_tick
SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'inst_id',
  timescaledb.compress_orderby   = 'ts_event DESC'
);
SELECT add_compression_policy('okx_core.fact_mark_price_tick', INTERVAL '6 hours');

-- open_interest_tick
ALTER TABLE okx_core.fact_open_interest_tick
SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'inst_id',
  timescaledb.compress_orderby   = 'ts_event DESC'
);
SELECT add_compression_policy('okx_core.fact_open_interest_tick', INTERVAL '6 hours');

-- orderbook_snapshot
ALTER TABLE okx_core.fact_orderbook_snapshot
SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'inst_id',
  timescaledb.compress_orderby   = 'ts_event DESC'
);
SELECT add_compression_policy('okx_core.fact_orderbook_snapshot', INTERVAL '6 hours');

-- orderbook_update
ALTER TABLE okx_core.fact_orderbook_update
SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'inst_id',
  timescaledb.compress_orderby   = 'ts_event DESC'
);
SELECT add_compression_policy('okx_core.fact_orderbook_update', INTERVAL '6 hours');

-- ticker_tick
ALTER TABLE okx_core.fact_ticker_tick
SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'inst_id',
  timescaledb.compress_orderby   = 'ts_event DESC'
);
SELECT add_compression_policy('okx_core.fact_ticker_tick', INTERVAL '6 hours');

-- trades_tick
ALTER TABLE okx_core.fact_trades_tick
SET (
  timescaledb.compress,
  timescaledb.compress_segmentby = 'inst_id',
  timescaledb.compress_orderby   = 'ts_event DESC'
);
SELECT add_compression_policy('okx_core.fact_trades_tick', INTERVAL '6 hours');

-- Политика: «через сколько времени после вставки можно chunk сжимать»:
-- Идея: последние 24 часа остаются разжатыми (на них чаще всего будут запросы), всё старше — сжато в несколько раз.
SELECT add_compression_policy(
  'okx_raw.funding_rates',
  compress_after        => NULL,
  compress_created_before => INTERVAL '1 day'
);
SELECT add_compression_policy(
  'okx_raw.index_tickers',
  compress_after        => NULL,
  compress_created_before => INTERVAL '1 day'
);
SELECT add_compression_policy(
  'okx_raw.mark_prices',
  compress_after        => NULL,
  compress_created_before => INTERVAL '1 day'
);
SELECT add_compression_policy(
  'okx_raw.open_interest',
  compress_after        => NULL,
  compress_created_before => INTERVAL '1 day'
);
SELECT add_compression_policy(
  'okx_raw.orderbook_snapshots',
  compress_after        => NULL,
  compress_created_before => INTERVAL '1 day'
);
SELECT add_compression_policy(
  'okx_raw.orderbook_updates',
  compress_after        => NULL,
  compress_created_before => INTERVAL '1 day'
);
SELECT add_compression_policy(
  'okx_raw.tickers',
  compress_after        => NULL,
  compress_created_before => INTERVAL '1 day'
);
SELECT add_compression_policy(
  'okx_raw.trades',
  compress_after        => NULL,
  compress_created_before => INTERVAL '1 day'
);
 
-- Настроить retention (TTL) — сколько историю реально держать
-- raw
SELECT remove_retention_policy('okx_raw.funding_rates');
SELECT remove_retention_policy('okx_raw.index_tickers');
SELECT remove_retention_policy('okx_raw.mark_prices');
SELECT remove_retention_policy('okx_raw.open_interest');
SELECT remove_retention_policy('okx_raw.orderbook_snapshots');
SELECT remove_retention_policy('okx_raw.orderbook_updates');
SELECT remove_retention_policy('okx_raw.tickers');
SELECT remove_retention_policy('okx_raw.trades');

SELECT add_retention_policy(
  'okx_raw.funding_rates',
  drop_after => NULL,
  drop_created_before => INTERVAL '180 days'
);
SELECT add_retention_policy(
  'okx_raw.index_tickers',
  drop_after => NULL,
  drop_created_before => INTERVAL '90 days'
);
SELECT add_retention_policy(
  'okx_raw.mark_prices',
  drop_after => NULL,
  drop_created_before => INTERVAL '90 days'
);
SELECT add_retention_policy(
  'okx_raw.open_interest',
  drop_after => NULL,
  drop_created_before => INTERVAL '90 days'
);
SELECT add_retention_policy(
  'okx_raw.orderbook_snapshots',
  drop_after => NULL,
  drop_created_before => INTERVAL '14 days'
);
SELECT add_retention_policy(
  'okx_raw.orderbook_updates',
  drop_after => NULL,
  drop_created_before => INTERVAL '14 days'
);
SELECT add_retention_policy(
  'okx_raw.tickers',
  drop_after => NULL,
  drop_created_before => INTERVAL '30 days'
);
SELECT add_retention_policy(
  'okx_raw.trades',
  drop_after => NULL,
  drop_created_before => INTERVAL '30 days'
);

-- core



-----------------------------------------------------------------------------------
-- навесим индексы 
CREATE INDEX IF NOT EXISTS idx_funding_rates_instid_ts_event_ms ON okx_raw.funding_rates (instid, ts_event_ms DESC);
CREATE INDEX IF NOT EXISTS idx_index_tickers_instid_ts_event_ms ON okx_raw.index_tickers (instid, ts_event_ms DESC);
CREATE INDEX IF NOT EXISTS idx_mark_prices_instid_ts_event_ms ON okx_raw.mark_prices (instid, ts_event_ms DESC);
CREATE INDEX IF NOT EXISTS idx_open_interest_instid_ts_event_ms ON okx_raw.open_interest (instid, ts_event_ms DESC);
CREATE INDEX IF NOT EXISTS idx_ob_snapshots_instid_ts_event_ms ON okx_raw.orderbook_snapshots (instid, ts_event_ms DESC);
CREATE INDEX IF NOT EXISTS idx_ob_updates_instid_ts_event_ms ON okx_raw.orderbook_updates (instid, ts_event_ms DESC);
CREATE INDEX IF NOT EXISTS idx_tickers_instid_ts_event_ms ON okx_raw.tickers (instid, ts_event_ms DESC);
CREATE INDEX IF NOT EXISTS idx_trades_instid_ts_event_ms ON okx_raw.trades (instid, ts_event_ms DESC);
CREATE INDEX IF NOT EXISTS idx_trades_ts_event_ms ON okx_raw.trades (ts_event_ms DESC);
CREATE INDEX IF NOT EXISTS idx_ob_updates_ts_event_ms ON okx_raw.orderbook_updates (ts_event_ms DESC);

-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
-- user creation
--CREATE ROLE user_r LOGIN PASSWORD 'password_r';
GRANT CONNECT ON DATABASE okx_hft TO superset_r, admin;
GRANT USAGE ON SCHEMA public, okx_raw, okx_core, okx_mart TO superset_r, admin;
GRANT SELECT ON ALL TABLES IN SCHEMA public, okx_raw, okx_core TO superset_r, admin;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public, okx_raw, okx_core TO superset_r, admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO superset_r, admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA okx_raw GRANT SELECT ON TABLES TO superset_r, admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO superset_r, admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA okx_raw GRANT USAGE, SELECT ON SEQUENCES TO superset_r, admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA okx_core GRANT USAGE, SELECT ON SEQUENCES TO superset_r, admin;
ALTER DEFAULT PRIVILEGES IN SCHEMA okx_mart GRANT USAGE, SELECT ON SEQUENCES TO superset_r, admin;
GRANT SELECT ON ALL TABLES IN SCHEMA okx_mart TO superset_r;

GRANT CONNECT ON DATABASE okx_hft TO superset_r;
GRANT USAGE ON SCHEMA public TO superset_r; -- и на другие схемы тоже, если нужны
-- затем для каждой схемы:
GRANT USAGE ON SCHEMA okx_core TO superset_r;
GRANT SELECT ON ALL TABLES IN SCHEMA okx_core TO superset_r;

-- for airflow
-- CREATE ROLE airflow_etl LOGIN PASSWORD 'airflow_etl' NOSUPERUSER NOCREATEDB NOCREATEROLE NOINHERIT;
GRANT CONNECT, TEMPORARY ON DATABASE okx_hft TO airflow_etl;
GRANT USAGE ON SCHEMA okx_raw, okx_core, okx_mart TO airflow_etl;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA okx_raw  TO airflow_etl;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA okx_core TO airflow_etl;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA okx_mart TO airflow_etl;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA okx_raw  TO airflow_etl;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA okx_core TO airflow_etl;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA okx_mart TO airflow_etl;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA okx_raw, okx_core, okx_mart TO airflow_etl;

ALTER DEFAULT PRIVILEGES IN SCHEMA okx_raw
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO airflow_etl;
ALTER DEFAULT PRIVILEGES IN SCHEMA okx_core
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO airflow_etl;
ALTER DEFAULT PRIVILEGES IN SCHEMA okx_mart
  GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO airflow_etl;
ALTER DEFAULT PRIVILEGES IN SCHEMA okx_raw
  GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO airflow_etl;
ALTER DEFAULT PRIVILEGES IN SCHEMA okx_core
  GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO airflow_etl;
ALTER DEFAULT PRIVILEGES IN SCHEMA okx_mart
  GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO airflow_etl;
ALTER DEFAULT PRIVILEGES IN SCHEMA okx_raw
  GRANT EXECUTE ON FUNCTIONS TO airflow_etl;
ALTER DEFAULT PRIVILEGES IN SCHEMA okx_core
  GRANT EXECUTE ON FUNCTIONS TO airflow_etl;
ALTER DEFAULT PRIVILEGES IN SCHEMA okx_mart
  GRANT EXECUTE ON FUNCTIONS TO airflow_etl;

-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
-- очистить все
TRUNCATE table okx_raw.funding_rates RESTART IDENTITY CASCADE;
TRUNCATE table okx_raw.index_tickers RESTART IDENTITY CASCADE;
TRUNCATE table okx_raw.mark_prices RESTART IDENTITY CASCADE;
TRUNCATE table okx_raw.open_interest RESTART IDENTITY CASCADE;
TRUNCATE table okx_raw.orderbook_snapshots RESTART IDENTITY CASCADE;
TRUNCATE table okx_raw.orderbook_updates RESTART IDENTITY CASCADE;
TRUNCATE table okx_raw.tickers RESTART IDENTITY CASCADE;
TRUNCATE table okx_raw.trades RESTART IDENTITY CASCADE;
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
-- make timezone UTC
SHOW timezone;         -- посмотреть что сейчас (у тебя, скорее всего, 'Asia/Bishkek' или 'GMT+6')
ALTER SYSTEM SET timezone = 'UTC';
SELECT pg_reload_conf();

SELECT current_user;  -- запомни имя
ALTER ROLE admin SET timezone = 'UTC';
ALTER DATABASE okx_hft SET timezone = 'UTC';

SELECT current_user, current_database();
SELECT name, setting, source FROM pg_settings WHERE name = 'TimeZone';
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
-- снос и восстановление мхемы
BEGIN;
DROP SCHEMA IF EXISTS okx_core CASCADE;
CREATE SCHEMA okx_core;
COMMIT;
-----------------------------------------------------------------------------------

-----------------------------------------------------------------------------------
-- сборка core

-- funding rate
-- Tick: уникальность по (inst_id, ts_event)
CREATE UNIQUE INDEX IF NOT EXISTS ux_fact_funding_rate_tick
ON okx_core.fact_funding_rate_tick (inst_id, ts_event);

-- Event: уникальность по (inst_id, funding_time) == ts_event
CREATE UNIQUE INDEX IF NOT EXISTS ux_fact_funding_rate_event
ON okx_core.fact_funding_rate_event (inst_id, ts_event);

CREATE OR REPLACE FUNCTION okx_core.sync_fact_funding_rate_tick(p_batch bigint DEFAULT 500000)
RETURNS TABLE(rows_upserted bigint, last_ts_ingest_ms bigint)
LANGUAGE plpgsql
AS $$
DECLARE
  v_last bigint := 0;
  v_new_last bigint := 0;
  v_rows bigint := 0;
BEGIN
  LOOP
    WITH batch AS (
      SELECT
        instid,
        ts_event_ms,
        ts_ingest_ms,
        fundingrate,
        fundingtime,
        nextfundingtime
      FROM okx_raw.funding_rates
      WHERE ts_ingest_ms > v_last
      ORDER BY ts_ingest_ms
      LIMIT p_batch
    ),
    upserted AS (
      INSERT INTO okx_core.fact_funding_rate_tick (
        inst_id, ts_event, ts_ingest, funding_rate, funding_time, next_funding_time
      )
      SELECT
        b.instid::text,
        to_timestamp(b.ts_event_ms / 1000.0),
        to_timestamp(b.ts_ingest_ms / 1000.0),
        b.fundingrate,
        to_timestamp(b.fundingtime / 1000.0),
        to_timestamp(b.nextfundingtime / 1000.0)
      FROM batch b
      ON CONFLICT (inst_id, ts_event) DO UPDATE
      SET
        ts_ingest         = EXCLUDED.ts_ingest,
        funding_rate      = EXCLUDED.funding_rate,
        funding_time      = EXCLUDED.funding_time,
        next_funding_time = EXCLUDED.next_funding_time
      WHERE okx_core.fact_funding_rate_tick.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest
      RETURNING 1
    )
    SELECT
      COALESCE((SELECT COUNT(*) FROM upserted), 0),
      COALESCE((SELECT MAX(ts_ingest_ms) FROM batch), v_last)
    INTO v_rows, v_new_last;

    EXIT WHEN v_new_last = v_last; -- batch пустой
    v_last := v_new_last;

    rows_upserted := v_rows;
    last_ts_ingest_ms := v_last;
    RETURN NEXT;
  END LOOP;
  RETURN;
END $$;

SELECT * FROM okx_core.sync_fact_funding_rate_tick(500000);

CREATE OR REPLACE FUNCTION okx_core.sync_fact_funding_rate_event(p_batch bigint DEFAULT 200000)
RETURNS TABLE(rows_upserted bigint, last_ts_ingest_ms bigint)
LANGUAGE plpgsql
AS $$
DECLARE
  v_last bigint := 0;
  v_new_last bigint := 0;
  v_rows bigint := 0;
BEGIN
  LOOP
    WITH raw_batch AS (
      SELECT *
      FROM okx_raw.funding_rates
      WHERE ts_ingest_ms > v_last
      ORDER BY ts_ingest_ms
      LIMIT p_batch
    ),
    -- схлопываем до 1 строки на событие (instid, fundingtime)
    events AS (
      SELECT DISTINCT ON (instid, fundingtime)
        instid,
        fundingtime,
        nextfundingtime,
        fundingrate,
        ts_ingest_ms
      FROM raw_batch
      ORDER BY instid, fundingtime, ts_ingest_ms DESC
    ),
    upserted AS (
      INSERT INTO okx_core.fact_funding_rate_event (
        inst_id, ts_event, ts_ingest, funding_rate, funding_time, next_funding_time
      )
      SELECT
        e.instid::text,
        to_timestamp(e.fundingtime / 1000.0) AS ts_event,
        to_timestamp(e.ts_ingest_ms / 1000.0),
        e.fundingrate,
        to_timestamp(e.fundingtime / 1000.0),
        to_timestamp(e.nextfundingtime / 1000.0)
      FROM events e
      ON CONFLICT (inst_id, ts_event) DO UPDATE
      SET
        ts_ingest         = EXCLUDED.ts_ingest,
        funding_rate      = EXCLUDED.funding_rate,
        funding_time      = EXCLUDED.funding_time,
        next_funding_time = EXCLUDED.next_funding_time
      WHERE okx_core.fact_funding_rate_event.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest
      RETURNING 1
    )
    SELECT
      COALESCE((SELECT COUNT(*) FROM upserted), 0),
      COALESCE((SELECT MAX(ts_ingest_ms) FROM raw_batch), v_last)
    INTO v_rows, v_new_last;

    EXIT WHEN v_new_last = v_last;
    v_last := v_new_last;
    rows_upserted := v_rows;
    last_ts_ingest_ms := v_last;
    RETURN NEXT;
  END LOOP;
  RETURN;
END $$;

SELECT * FROM okx_core.sync_fact_funding_rate_event(200000);

CREATE OR REPLACE FUNCTION okx_core.trg_funding_rates_to_core()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  -- tick: каждая строка
  INSERT INTO okx_core.fact_funding_rate_tick (
    inst_id, ts_event, ts_ingest, funding_rate, funding_time, next_funding_time
  )
  VALUES (
    NEW.instid::text,
    to_timestamp(NEW.ts_event_ms / 1000.0),
    to_timestamp(NEW.ts_ingest_ms / 1000.0),
    NEW.fundingrate,
    to_timestamp(NEW.fundingtime / 1000.0),
    to_timestamp(NEW.nextfundingtime / 1000.0)
  )
  ON CONFLICT (inst_id, ts_event) DO UPDATE
  SET
    ts_ingest         = EXCLUDED.ts_ingest,
    funding_rate      = EXCLUDED.funding_rate,
    funding_time      = EXCLUDED.funding_time,
    next_funding_time = EXCLUDED.next_funding_time
  WHERE okx_core.fact_funding_rate_tick.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest;

  -- event: 1 строка на fundingtime (последняя победит)
  INSERT INTO okx_core.fact_funding_rate_event (
    inst_id, ts_event, ts_ingest, funding_rate, funding_time, next_funding_time
  )
  VALUES (
    NEW.instid::text,
    to_timestamp(NEW.fundingtime / 1000.0),          -- ts_event = funding_time
    to_timestamp(NEW.ts_ingest_ms / 1000.0),
    NEW.fundingrate,
    to_timestamp(NEW.fundingtime / 1000.0),
    to_timestamp(NEW.nextfundingtime / 1000.0)
  )
  ON CONFLICT (inst_id, ts_event) DO UPDATE
  SET
    ts_ingest         = EXCLUDED.ts_ingest,
    funding_rate      = EXCLUDED.funding_rate,
    funding_time      = EXCLUDED.funding_time,
    next_funding_time = EXCLUDED.next_funding_time
  WHERE okx_core.fact_funding_rate_event.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_funding_rates_to_core ON okx_raw.funding_rates;

CREATE TRIGGER trg_funding_rates_to_core
AFTER INSERT ON okx_raw.funding_rates
FOR EACH ROW
EXECUTE FUNCTION okx_core.trg_funding_rates_to_core();

INSERT INTO okx_core.fact_funding_rate_event (
  inst_id, ts_event, ts_ingest, funding_rate, funding_time, next_funding_time
)
SELECT
  r.instid::text                                         AS inst_id,
  to_timestamp(r.fundingtime / 1000.0)                   AS ts_event,       -- event time = funding_time
  to_timestamp(r.ts_ingest_ms / 1000.0)                  AS ts_ingest,
  r.fundingrate                                          AS funding_rate,
  to_timestamp(r.fundingtime / 1000.0)                   AS funding_time,
  to_timestamp(r.nextfundingtime / 1000.0)               AS next_funding_time
FROM (
  SELECT DISTINCT ON (instid, fundingtime)
    instid, fundingtime, nextfundingtime, fundingrate, ts_ingest_ms
  FROM okx_raw.funding_rates
  ORDER BY instid, fundingtime, ts_ingest_ms DESC
) r
ON CONFLICT (inst_id, ts_event) DO UPDATE
SET
  ts_ingest         = EXCLUDED.ts_ingest,
  funding_rate      = EXCLUDED.funding_rate,
  funding_time      = EXCLUDED.funding_time,
  next_funding_time = EXCLUDED.next_funding_time
WHERE okx_core.fact_funding_rate_event.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest;

-- fact_index_tick
CREATE UNIQUE INDEX IF NOT EXISTS ux_fact_index_tick
ON okx_core.fact_index_tick (inst_id, ts_event);

CREATE OR REPLACE FUNCTION okx_core.sync_fact_index_tick(p_batch bigint DEFAULT 500000)
RETURNS TABLE(rows_upserted bigint, last_ts_ingest_ms bigint)
LANGUAGE plpgsql
AS $$
DECLARE
  v_last bigint := 0;
  v_new_last bigint;
  v_rows bigint;
BEGIN
  LOOP
    WITH batch AS (
      SELECT
        instid,
        ts_event_ms,
        ts_ingest_ms,
        idxpx,
        open24h,
        high24h,
        low24h,
        sodutc0,
        sodutc8
      FROM okx_raw.index_tickers
      WHERE ts_ingest_ms > v_last
      ORDER BY ts_ingest_ms
      LIMIT p_batch
    ),
    upserted AS (
      INSERT INTO okx_core.fact_index_tick (
        inst_id, ts_event, ts_ingest,
        index_px, open_24h, high_24h, low_24h, sod_utc0_px, sod_utc8_px
      )
      SELECT
        b.instid::text,
        to_timestamp(b.ts_event_ms / 1000.0),
        to_timestamp(b.ts_ingest_ms / 1000.0),
        b.idxpx,
        b.open24h,
        b.high24h,
        b.low24h,
        b.sodutc0,
        b.sodutc8
      FROM batch b
      ON CONFLICT (inst_id, ts_event) DO UPDATE
      SET
        ts_ingest   = EXCLUDED.ts_ingest,
        index_px    = EXCLUDED.index_px,
        open_24h    = EXCLUDED.open_24h,
        high_24h    = EXCLUDED.high_24h,
        low_24h     = EXCLUDED.low_24h,
        sod_utc0_px = EXCLUDED.sod_utc0_px,
        sod_utc8_px = EXCLUDED.sod_utc8_px
      WHERE okx_core.fact_index_tick.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest
      RETURNING 1
    )
    SELECT
      COALESCE((SELECT COUNT(*) FROM upserted), 0),
      COALESCE((SELECT MAX(ts_ingest_ms) FROM batch), v_last)
    INTO v_rows, v_new_last;
    EXIT WHEN v_new_last = v_last;
    v_last := v_new_last;
    rows_upserted := v_rows;
    last_ts_ingest_ms := v_last;
    RETURN NEXT;
  END LOOP;
  RETURN;
END $$;

SELECT * FROM okx_core.sync_fact_index_tick(500000);

CREATE OR REPLACE FUNCTION okx_core.trg_index_tickers_to_core()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO okx_core.fact_index_tick (
    inst_id, ts_event, ts_ingest,
    index_px, open_24h, high_24h, low_24h, sod_utc0_px, sod_utc8_px
  )
  VALUES (
    NEW.instid::text,
    to_timestamp(NEW.ts_event_ms / 1000.0),
    to_timestamp(NEW.ts_ingest_ms / 1000.0),
    NEW.idxpx,
    NEW.open24h,
    NEW.high24h,
    NEW.low24h,
    NEW.sodutc0,
    NEW.sodutc8
  )
  ON CONFLICT (inst_id, ts_event) DO UPDATE
  SET
    ts_ingest   = EXCLUDED.ts_ingest,
    index_px    = EXCLUDED.index_px,
    open_24h    = EXCLUDED.open_24h,
    high_24h    = EXCLUDED.high_24h,
    low_24h     = EXCLUDED.low_24h,
    sod_utc0_px = EXCLUDED.sod_utc0_px,
    sod_utc8_px = EXCLUDED.sod_utc8_px
  WHERE okx_core.fact_index_tick.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_index_tickers_to_core ON okx_raw.index_tickers;

CREATE TRIGGER trg_index_tickers_to_core
AFTER INSERT ON okx_raw.index_tickers
FOR EACH ROW
EXECUTE FUNCTION okx_core.trg_index_tickers_to_core();

INSERT INTO okx_core.fact_index_tick (
  inst_id, ts_event, ts_ingest,
  index_px, open_24h, high_24h, low_24h, sod_utc0_px, sod_utc8_px
)
SELECT
  r.instid::text,
  to_timestamp(r.ts_event_ms / 1000.0),
  to_timestamp(r.ts_ingest_ms / 1000.0),
  r.idxpx,
  r.open24h,
  r.high24h,
  r.low24h,
  r.sodutc0,
  r.sodutc8
FROM okx_raw.index_tickers r
LEFT JOIN okx_core.fact_index_tick c
  ON c.inst_id = r.instid::text
 AND c.ts_event = to_timestamp(r.ts_event_ms / 1000.0)
WHERE c.inst_id IS NULL
ON CONFLICT DO NOTHING;

-- fact_mark_price_tick
CREATE UNIQUE INDEX IF NOT EXISTS ux_fact_mark_price_tick
ON okx_core.fact_mark_price_tick (inst_id, ts_event);

CREATE OR REPLACE FUNCTION okx_core.sync_fact_mark_price_tick(p_batch bigint DEFAULT 500000)
RETURNS TABLE(rows_upserted bigint, last_ts_ingest_ms bigint)
LANGUAGE plpgsql
AS $$
DECLARE
  v_last bigint := 0;
  v_new_last bigint;
  v_rows bigint;
BEGIN
  LOOP
    WITH batch AS (
      SELECT
        instid,
        ts_event_ms,
        ts_ingest_ms,
        markpx
      FROM okx_raw.mark_prices
      WHERE ts_ingest_ms > v_last
      ORDER BY ts_ingest_ms
      LIMIT p_batch
    ),
    upserted AS (
      INSERT INTO okx_core.fact_mark_price_tick (
        inst_id, ts_event, ts_ingest, mark_px
      )
      SELECT
        b.instid::text,
        to_timestamp(b.ts_event_ms / 1000.0),
        to_timestamp(b.ts_ingest_ms / 1000.0),
        b.markpx
      FROM batch b
      ON CONFLICT (inst_id, ts_event) DO UPDATE
      SET
        ts_ingest = EXCLUDED.ts_ingest,
        mark_px   = EXCLUDED.mark_px
      WHERE okx_core.fact_mark_price_tick.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest
      RETURNING 1
    )
    SELECT
      COALESCE((SELECT COUNT(*) FROM upserted), 0),
      COALESCE((SELECT MAX(ts_ingest_ms) FROM batch), v_last)
    INTO v_rows, v_new_last;
    EXIT WHEN v_new_last = v_last;
    v_last := v_new_last;
    rows_upserted := v_rows;
    last_ts_ingest_ms := v_last;
    RETURN NEXT;
  END LOOP;
  RETURN;
END $$;

SELECT * FROM okx_core.sync_fact_mark_price_tick(500000::bigint);

CREATE OR REPLACE FUNCTION okx_core.trg_mark_prices_to_core()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO okx_core.fact_mark_price_tick (
    inst_id, ts_event, ts_ingest, mark_px
  )
  VALUES (
    NEW.instid::text,
    to_timestamp(NEW.ts_event_ms / 1000.0),
    to_timestamp(NEW.ts_ingest_ms / 1000.0),
    NEW.markpx
  )
  ON CONFLICT (inst_id, ts_event) DO UPDATE
  SET
    ts_ingest = EXCLUDED.ts_ingest,
    mark_px   = EXCLUDED.mark_px
  WHERE okx_core.fact_mark_price_tick.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_mark_prices_to_core ON okx_raw.mark_prices;

CREATE TRIGGER trg_mark_prices_to_core
AFTER INSERT ON okx_raw.mark_prices
FOR EACH ROW
EXECUTE FUNCTION okx_core.trg_mark_prices_to_core();

INSERT INTO okx_core.fact_mark_price_tick (inst_id, ts_event, ts_ingest, mark_px)
SELECT
  r.instid::text,
  to_timestamp(r.ts_event_ms / 1000.0),
  to_timestamp(r.ts_ingest_ms / 1000.0),
  r.markpx
FROM okx_raw.mark_prices r
LEFT JOIN okx_core.fact_mark_price_tick c
  ON c.inst_id = r.instid::text
 AND c.ts_event = to_timestamp(r.ts_event_ms / 1000.0)
WHERE c.inst_id IS NULL
ON CONFLICT DO NOTHING;

-- fact_open_interest_tick
CREATE UNIQUE INDEX IF NOT EXISTS ux_fact_open_interest_tick
ON okx_core.fact_open_interest_tick (inst_id, ts_event);

CREATE OR REPLACE FUNCTION okx_core.sync_fact_open_interest_tick(p_batch bigint DEFAULT 500000)
RETURNS TABLE(rows_upserted bigint, last_ts_ingest_ms bigint)
LANGUAGE plpgsql
AS $$
DECLARE
  v_last bigint := 0;
  v_new_last bigint;
  v_rows bigint;
BEGIN
  LOOP
    WITH batch AS (
      SELECT
        instid,
        ts_event_ms,
        ts_ingest_ms,
        oi,
        oiccy
      FROM okx_raw.open_interest
      WHERE ts_ingest_ms > v_last
      ORDER BY ts_ingest_ms
      LIMIT p_batch
    ),
    upserted AS (
      INSERT INTO okx_core.fact_open_interest_tick (
        inst_id, ts_event, ts_ingest, open_interest, open_interest_ccy
      )
      SELECT
        b.instid::text,
        to_timestamp(b.ts_event_ms / 1000.0),
        to_timestamp(b.ts_ingest_ms / 1000.0),
        b.oi,
        b.oiccy
      FROM batch b
      ON CONFLICT (inst_id, ts_event) DO UPDATE
      SET
        ts_ingest          = EXCLUDED.ts_ingest,
        open_interest      = EXCLUDED.open_interest,
        open_interest_ccy  = EXCLUDED.open_interest_ccy
      WHERE okx_core.fact_open_interest_tick.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest
      RETURNING 1
    )
    SELECT
      COALESCE((SELECT COUNT(*) FROM upserted), 0),
      COALESCE((SELECT MAX(ts_ingest_ms) FROM batch), v_last)
    INTO v_rows, v_new_last;
    EXIT WHEN v_new_last = v_last;
    v_last := v_new_last;
    rows_upserted := v_rows;
    last_ts_ingest_ms := v_last;
    RETURN NEXT;
  END LOOP;
  RETURN;
END $$;

SELECT * FROM okx_core.sync_fact_open_interest_tick();

CREATE OR REPLACE FUNCTION okx_core.trg_open_interest_to_core()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO okx_core.fact_open_interest_tick (
    inst_id, ts_event, ts_ingest, open_interest, open_interest_ccy
  )
  VALUES (
    NEW.instid::text,
    to_timestamp(NEW.ts_event_ms / 1000.0),
    to_timestamp(NEW.ts_ingest_ms / 1000.0),
    NEW.oi,
    NEW.oiccy
  )
  ON CONFLICT (inst_id, ts_event) DO UPDATE
  SET
    ts_ingest         = EXCLUDED.ts_ingest,
    open_interest     = EXCLUDED.open_interest,
    open_interest_ccy = EXCLUDED.open_interest_ccy
  WHERE okx_core.fact_open_interest_tick.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_open_interest_to_core ON okx_raw.open_interest;

CREATE TRIGGER trg_open_interest_to_core
AFTER INSERT ON okx_raw.open_interest
FOR EACH ROW
EXECUTE FUNCTION okx_core.trg_open_interest_to_core();

INSERT INTO okx_core.fact_open_interest_tick (
  inst_id, ts_event, ts_ingest, open_interest, open_interest_ccy
)
SELECT
  r.instid::text,
  to_timestamp(r.ts_event_ms / 1000.0),
  to_timestamp(r.ts_ingest_ms / 1000.0),
  r.oi,
  r.oiccy
FROM okx_raw.open_interest r
LEFT JOIN okx_core.fact_open_interest_tick c
  ON c.inst_id = r.instid::text
 AND c.ts_event = to_timestamp(r.ts_event_ms / 1000.0)
WHERE c.inst_id IS NULL
ON CONFLICT DO NOTHING;

-- fact_orderbook_snapshot
CREATE UNIQUE INDEX IF NOT EXISTS ux_fact_orderbook_snapshot
ON okx_core.fact_orderbook_snapshot (inst_id, ts_event, side, level_no);


CREATE OR REPLACE FUNCTION okx_core.sync_fact_orderbook_snapshot(p_batch bigint DEFAULT 500000)
RETURNS TABLE(rows_upserted bigint, last_ts_ingest_ms bigint)
LANGUAGE plpgsql
AS $function$
DECLARE
  v_last bigint := 0;
  v_new_last bigint;
  v_rows bigint;
BEGIN
  LOOP
    WITH batch AS (
      SELECT snapshot_id, instid, ts_event_ms, ts_ingest_ms, side, level, price, size
      FROM okx_raw.orderbook_snapshots
      WHERE ts_ingest_ms > v_last
      ORDER BY ts_ingest_ms
      LIMIT p_batch
    ),
    upserted AS (
      INSERT INTO okx_core.fact_orderbook_snapshot (
        snapshot_id, inst_id, ts_event, side, level_no, price_px, size_qty, ts_ingest
      )
      SELECT
        b.snapshot_id,
        b.instid::text,
        to_timestamp(b.ts_event_ms / 1000.0),
        CASE WHEN b.side = 1 THEN 'bid'
             WHEN b.side = 2 THEN 'ask'
             ELSE b.side::text END,
        b.level,
        b.price,
        b.size,
        to_timestamp(b.ts_ingest_ms / 1000.0)
      FROM batch b
      ON CONFLICT (inst_id, ts_event, side, level_no) DO UPDATE
      SET
        snapshot_id = EXCLUDED.snapshot_id,
        price_px    = EXCLUDED.price_px,
        size_qty    = EXCLUDED.size_qty,
        ts_ingest   = EXCLUDED.ts_ingest
      WHERE okx_core.fact_orderbook_snapshot.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest
      RETURNING 1
    )
    SELECT
      COALESCE((SELECT COUNT(*) FROM upserted), 0),
      COALESCE((SELECT MAX(ts_ingest_ms) FROM batch), v_last)
    INTO v_rows, v_new_last;

    EXIT WHEN v_new_last = v_last;
    v_last := v_new_last;
    rows_upserted := v_rows;
    last_ts_ingest_ms := v_last;
    RETURN NEXT;
  END LOOP;
  RETURN;
END $function$;

SELECT * FROM okx_core.sync_fact_orderbook_snapshot();

CREATE OR REPLACE FUNCTION okx_core.trg_orderbook_snapshots_to_core()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO okx_core.fact_orderbook_snapshot (
    snapshot_id, inst_id, ts_event, side, level_no, price_px, size_qty, ts_ingest
  )
  VALUES (
    NEW.snapshot_id,
    NEW.instid::text,
    to_timestamp(NEW.ts_event_ms / 1000.0),
    CASE
      WHEN NEW.side = 1 THEN 'bid'
      WHEN NEW.side = 2 THEN 'ask'
      ELSE NEW.side::text
    END,
    NEW.level,
    NEW.price,
    NEW.size,
    to_timestamp(NEW.ts_ingest_ms / 1000.0)
  )
  ON CONFLICT (snapshot_id, side, level_no) DO UPDATE
  SET
    inst_id   = EXCLUDED.inst_id,
    ts_event  = EXCLUDED.ts_event,
    price_px  = EXCLUDED.price_px,
    size_qty  = EXCLUDED.size_qty,
    ts_ingest = EXCLUDED.ts_ingest
  WHERE okx_core.fact_orderbook_snapshot.ts_ingest IS DISTINCT FROM EXCLUDED.ts_ingest;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_orderbook_snapshots_to_core ON okx_raw.orderbook_snapshots;

CREATE TRIGGER trg_orderbook_snapshots_to_core
AFTER INSERT ON okx_raw.orderbook_snapshots
FOR EACH ROW
EXECUTE FUNCTION okx_core.trg_orderbook_snapshots_to_core();

INSERT INTO okx_core.fact_orderbook_snapshot (
  snapshot_id, inst_id, ts_event, side, level_no, price_px, size_qty, ts_ingest
)
SELECT
  r.snapshot_id,
  r.instid::text,
  to_timestamp(r.ts_event_ms / 1000.0),
  CASE WHEN r.side=1 THEN 'bid' WHEN r.side=2 THEN 'ask' ELSE r.side::text END,
  r.level,
  r.price,
  r.size,
  to_timestamp(r.ts_ingest_ms / 1000.0)
FROM okx_raw.orderbook_snapshots r
LEFT JOIN okx_core.fact_orderbook_snapshot c
  ON c.snapshot_id = r.snapshot_id
 AND c.side = (CASE WHEN r.side=1 THEN 'bid' WHEN r.side=2 THEN 'ask' ELSE r.side::text END)
 AND c.level_no = r.level
WHERE c.snapshot_id IS NULL
ON CONFLICT DO NOTHING;












WITH r AS (SELECT max(ts_ingest_ms) raw_last_ms FROM okx_raw.orderbook_updates),
     c AS (SELECT max(ts_ingest) core_last_ts FROM okx_core.fact_orderbook_update_level)
SELECT
  (to_timestamp(r.raw_last_ms/1000.0) AT TIME ZONE 'UTC')::timestamptz AS raw_last_utc,
  c.core_last_ts AS core_last_utc,
  EXTRACT(EPOCH FROM ((to_timestamp(r.raw_last_ms/1000.0) AT TIME ZONE 'UTC')::timestamptz - c.core_last_ts))::bigint AS lag_seconds
FROM r,c;

