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
SELECT remove_retention_policy('okx_core.fact_funding_rate_event', if_exists => TRUE);
SELECT remove_retention_policy('okx_core.fact_funding_rate_tick', if_exists => TRUE);
SELECT remove_retention_policy('okx_core.fact_index_tick', if_exists => TRUE);
SELECT remove_retention_policy('okx_core.fact_mark_price_tick', if_exists => TRUE);
SELECT remove_retention_policy('okx_core.fact_open_interest_tick', if_exists => TRUE);
SELECT remove_retention_policy('okx_core.fact_orderbook_snapshot', if_exists => TRUE);
SELECT remove_retention_policy('okx_core.fact_orderbook_update', if_exists => TRUE);
SELECT remove_retention_policy('okx_core.fact_orderbook_update_level', if_exists => TRUE);
SELECT remove_retention_policy('okx_core.fact_ticker_tick', if_exists => TRUE);
SELECT remove_retention_policy('okx_core.fact_trades_tick', if_exists => TRUE);

SELECT add_retention_policy(
  'okx_core.etl_state',
  drop_after => NULL,
  drop_created_before => INTERVAL '365 days'
);
SELECT add_retention_policy(
  'okx_core.fact_funding_rate_event',
  drop_after => NULL,
  drop_created_before => INTERVAL '180 days'
);
SELECT add_retention_policy(
  'okx_core.fact_funding_rate_tick',
  drop_after => NULL,
  drop_created_before => INTERVAL '180 days'
);
SELECT add_retention_policy(
  'okx_core.fact_index_tick',
  drop_after => NULL,
  drop_created_before => INTERVAL '90 days'
);
SELECT add_retention_policy(
  'okx_core.fact_mark_price_tick',
  drop_after => NULL,
  drop_created_before => INTERVAL '90 days'
);
SELECT add_retention_policy(
  'okx_core.fact_open_interest_tick',
  drop_after => NULL,
  drop_created_before => INTERVAL '90 days'
);
SELECT add_retention_policy(
  'okx_core.fact_orderbook_snapshot',
  drop_after => NULL,
  drop_created_before => INTERVAL '14 days'
);
SELECT add_retention_policy(
  'okx_core.fact_orderbook_update',
  drop_after => NULL,
  drop_created_before => INTERVAL '14 days'
);
SELECT add_retention_policy(
  'okx_core.fact_orderbook_update_level',
  drop_after => NULL,
  drop_created_before => INTERVAL '14 days'
);
SELECT add_retention_policy(
  'okx_core.fact_ticker_tick',
  drop_after => NULL,
  drop_created_before => INTERVAL '30 days'
);
SELECT add_retention_policy(
  'okx_core.fact_trades_tick',
  drop_after => NULL,
  drop_created_before => INTERVAL '30 days'
);

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
 
 
 -- разрешить “видеть” схему
GRANT USAGE ON SCHEMA okx_feat TO airflow_etl;

-- если DAG только читает/пишет в таблицу:
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA okx_feat TO airflow_etl;

-- на всякий (если есть sequences/identity, бывает нужно при INSERT)
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA okx_feat TO airflow_etl;

ALTER DEFAULT PRIVILEGES IN SCHEMA okx_feat
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO airflow_etl;

ALTER DEFAULT PRIVILEGES IN SCHEMA okx_feat
GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO airflow_etl;


-----------------------------------------------------------------------------------


