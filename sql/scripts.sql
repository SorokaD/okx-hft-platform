-- OKX Core v1: canonical fact tables
-- Schema okx_core must already exist

BEGIN;

-- 1) Funding rates (events)
CREATE TABLE IF NOT EXISTS okx_core.fact_funding_rate_event (
    inst_id            text        NOT NULL,
    ts_event           timestamptz NOT NULL,
    ts_ingest          timestamptz NOT NULL,
    funding_rate       double precision NOT NULL,
    funding_time       timestamptz NULL,
    next_funding_time  timestamptz NULL,
    PRIMARY KEY (inst_id, ts_event)
);

CREATE INDEX IF NOT EXISTS ix_funding_rate_event_inst_ts_event
    ON okx_core.fact_funding_rate_event (inst_id, ts_event DESC);

CREATE INDEX IF NOT EXISTS ix_funding_rate_event_ts_ingest
    ON okx_core.fact_funding_rate_event (ts_ingest DESC);


-- 2) Index tick
CREATE TABLE IF NOT EXISTS okx_core.fact_index_tick (
    inst_id      text        NOT NULL,
    ts_event     timestamptz NOT NULL,
    ts_ingest    timestamptz NOT NULL,
    index_px     double precision NOT NULL,
    open_24h     double precision NULL,
    high_24h     double precision NULL,
    low_24h      double precision NULL,
    sod_utc0_px  double precision NULL,
    sod_utc8_px  double precision NULL,
    PRIMARY KEY (inst_id, ts_event)
);

CREATE INDEX IF NOT EXISTS ix_index_tick_inst_ts_event
    ON okx_core.fact_index_tick (inst_id, ts_event DESC);

CREATE INDEX IF NOT EXISTS ix_index_tick_ts_ingest
    ON okx_core.fact_index_tick (ts_ingest DESC);


-- 3) Mark price tick
CREATE TABLE IF NOT EXISTS okx_core.fact_mark_price_tick (
    inst_id      text        NOT NULL,
    ts_event     timestamptz NOT NULL,
    ts_ingest    timestamptz NOT NULL,
    mark_px      double precision NOT NULL,
    index_px     double precision NULL,
    idx_ts_event timestamptz NULL,  -- normalized from okx_raw.idxts (format to be confirmed during ETL)
    PRIMARY KEY (inst_id, ts_event)
);

CREATE INDEX IF NOT EXISTS ix_mark_price_tick_inst_ts_event
    ON okx_core.fact_mark_price_tick (inst_id, ts_event DESC);

CREATE INDEX IF NOT EXISTS ix_mark_price_tick_ts_ingest
    ON okx_core.fact_mark_price_tick (ts_ingest DESC);


-- 4) Ticker tick (best bid/ask + last + 24h stats)
CREATE TABLE IF NOT EXISTS okx_core.fact_ticker_tick (
    inst_id       text        NOT NULL,
    ts_event      timestamptz NOT NULL,
    ts_ingest     timestamptz NOT NULL,
    last_px       double precision NULL,
    bid_px        double precision NULL,
    bid_sz        double precision NULL,
    ask_px        double precision NULL,
    ask_sz        double precision NULL,
    open_24h      double precision NULL,
    high_24h      double precision NULL,
    low_24h       double precision NULL,
    vol_24h       double precision NULL,
    vol_ccy_24h   double precision NULL,
    PRIMARY KEY (inst_id, ts_event)
);

CREATE INDEX IF NOT EXISTS ix_ticker_tick_inst_ts_event
    ON okx_core.fact_ticker_tick (inst_id, ts_event DESC);

CREATE INDEX IF NOT EXISTS ix_ticker_tick_ts_ingest
    ON okx_core.fact_ticker_tick (ts_ingest DESC);


-- 5) Trades tick
CREATE TABLE IF NOT EXISTS okx_core.fact_trades_tick (
    inst_id     text        NOT NULL,
    ts_event    timestamptz NOT NULL,
    ts_ingest   timestamptz NOT NULL,
    trade_id    text        NOT NULL,
    trade_px    double precision NOT NULL,
    trade_sz    double precision NOT NULL,
    side        text        NOT NULL, -- expected values: 'buy'/'sell' (enforced in ETL or constraint later)
    PRIMARY KEY (inst_id, trade_id)
);

CREATE INDEX IF NOT EXISTS ix_trades_tick_inst_ts_event
    ON okx_core.fact_trades_tick (inst_id, ts_event DESC);

CREATE INDEX IF NOT EXISTS ix_trades_tick_ts_ingest
    ON okx_core.fact_trades_tick (ts_ingest DESC);


-- 6) Open interest tick
CREATE TABLE IF NOT EXISTS okx_core.fact_open_interest_tick (
    inst_id             text        NOT NULL,
    ts_event            timestamptz NOT NULL,
    ts_ingest           timestamptz NOT NULL,
    open_interest       double precision NOT NULL,
    open_interest_ccy   double precision NULL,
    PRIMARY KEY (inst_id, ts_event)
);

CREATE INDEX IF NOT EXISTS ix_open_interest_tick_inst_ts_event
    ON okx_core.fact_open_interest_tick (inst_id, ts_event DESC);

CREATE INDEX IF NOT EXISTS ix_open_interest_tick_ts_ingest
    ON okx_core.fact_open_interest_tick (ts_ingest DESC);


-- 7) Orderbook snapshot (normalized "level rows")
-- IMPORTANT: we treat each (snapshot_id, inst_id, side, level_no) as unique.
CREATE TABLE IF NOT EXISTS okx_core.fact_orderbook_snapshot (
    snapshot_id uuid        NOT NULL,
    inst_id     text        NOT NULL,
    ts_event    timestamptz NOT NULL,
    side        text        NOT NULL, -- 'bid'/'ask'
    level_no    smallint    NOT NULL,
    price_px    double precision NOT NULL,
    size_qty    double precision NOT NULL,
    PRIMARY KEY (snapshot_id, inst_id, side, level_no)
);

CREATE INDEX IF NOT EXISTS ix_ob_snapshot_inst_ts_event
    ON okx_core.fact_orderbook_snapshot (inst_id, ts_event DESC);


-- 8) Orderbook updates (delta payloads)
-- NOTE: okx_raw.orderbook_updates currently has no ts_ingest_ms (per your screenshots).
-- We keep ts_ingest as NOT NULL, but it must be provided by ETL (or we'll add it to raw).
CREATE TABLE IF NOT EXISTS okx_core.fact_orderbook_update (
    inst_id      text        NOT NULL,
    ts_event     timestamptz NOT NULL,
    ts_ingest    timestamptz NOT NULL,
    bids_delta   jsonb       NULL,
    asks_delta   jsonb       NULL,
    checksum     bigint      NULL,
    PRIMARY KEY (inst_id, ts_event)
);

CREATE INDEX IF NOT EXISTS ix_ob_update_inst_ts_event
    ON okx_core.fact_orderbook_update (inst_id, ts_event DESC);

CREATE INDEX IF NOT EXISTS ix_ob_update_ts_ingest
    ON okx_core.fact_orderbook_update (ts_ingest DESC);

COMMIT;





INSERT INTO okx_core.fact_funding_rate_event (
    inst_id,
    ts_event,
    ts_ingest,
    funding_rate,
    funding_time,
    next_funding_time
)
SELECT
    instid                                        AS inst_id,
    to_timestamp(ts_event_ms / 1000.0)            AS ts_event,
    to_timestamp(ts_ingest_ms / 1000.0)            AS ts_ingest,
    fundingrate                                   AS funding_rate,
    to_timestamp(fundingtime / 1000.0)             AS funding_time,
    to_timestamp(nextfundingtime / 1000.0)         AS next_funding_time
FROM okx_raw.funding_rates
ON CONFLICT (inst_id, ts_event) DO UPDATE
SET
    ts_ingest         = EXCLUDED.ts_ingest,
    funding_rate      = EXCLUDED.funding_rate,
    funding_time      = EXCLUDED.funding_time,
    next_funding_time = EXCLUDED.next_funding_time;


INSERT INTO okx_core.fact_index_tick (
    inst_id,
    ts_event,
    ts_ingest,
    index_px,
    open_24h,
    high_24h,
    low_24h,
    sod_utc0_px,
    sod_utc8_px
)
SELECT
    instid                             AS inst_id,
    to_timestamp(ts_event_ms / 1000.0) AS ts_event,
    to_timestamp(ts_ingest_ms / 1000.0) AS ts_ingest,
    idxpx                              AS index_px,
    open24h                            AS open_24h,
    high24h                            AS high_24h,
    low24h                             AS low_24h,
    sodutc0                            AS sod_utc0_px,
    sodutc8                            AS sod_utc8_px
FROM okx_raw.index_tickers
ON CONFLICT (inst_id, ts_event) DO UPDATE
SET
    ts_ingest   = EXCLUDED.ts_ingest,
    index_px    = EXCLUDED.index_px,
    open_24h    = EXCLUDED.open_24h,
    high_24h    = EXCLUDED.high_24h,
    low_24h     = EXCLUDED.low_24h,
    sod_utc0_px = EXCLUDED.sod_utc0_px,
    sod_utc8_px = EXCLUDED.sod_utc8_px;


DO $$
DECLARE
  t_min bigint;
  t_max bigint;
  step  bigint := 24 * 60 * 60 * 1000;  -- 1 day in ms
  t     bigint;
BEGIN
  SELECT min(ts_event_ms), max(ts_event_ms)
    INTO t_min, t_max
  FROM okx_raw.mark_prices;
  t := t_min;
  WHILE t <= t_max LOOP
    INSERT INTO okx_core.fact_mark_price_tick (
      inst_id, ts_event, ts_ingest, mark_px
    )
    SELECT DISTINCT ON (instid, ts_event_ms)
      instid,
      to_timestamp(ts_event_ms / 1000.0),
      to_timestamp(ts_ingest_ms / 1000.0),
      markpx
    FROM okx_raw.mark_prices
    WHERE ts_event_ms >= t
      AND ts_event_ms <  t + step
    ORDER BY instid, ts_event_ms, ts_ingest_ms DESC;
    t := t + step;
  END LOOP;
END $$;





SELECT
  instid,
  last,
  bidpx, bidsz,
  askpx, asksz,
  open24h, high24h, low24h,
  vol24h, volccy24h,
  ts_event_ms, ts_ingest_ms
FROM okx_raw.tickers
ORDER BY ts_event_ms DESC
LIMIT 5;


TRUNCATE TABLE okx_core.fact_ticker_tick;

DO $$
DECLARE
  t_min bigint;
  t_max bigint;
  step  bigint := 24 * 60 * 60 * 1000;  -- 1 day in ms
  t     bigint;
BEGIN
  SELECT min(ts_event_ms), max(ts_event_ms)
    INTO t_min, t_max
  FROM okx_raw.tickers;
  t := t_min;
  WHILE t <= t_max LOOP
    INSERT INTO okx_core.fact_ticker_tick (
      inst_id, ts_event, ts_ingest,
      last_px,
      bid_px, bid_sz,
      ask_px, ask_sz,
      open_24h, high_24h, low_24h,
      vol_24h, vol_ccy_24h
    )
    SELECT DISTINCT ON (instid, ts_event_ms)
      instid,
      to_timestamp(ts_event_ms / 1000.0),
      to_timestamp(ts_ingest_ms / 1000.0),
      last,
      bidpx, bidsz,
      askpx, asksz,
      open24h, high24h, low24h,
      vol24h, volccy24h
    FROM okx_raw.tickers
    WHERE ts_event_ms >= t
      AND ts_event_ms <  t + step
    ORDER BY instid, ts_event_ms, ts_ingest_ms DESC;
    t := t + step;
  END LOOP;
END $$;




DO $$
DECLARE
  v_last bigint := 0;
  v_new_last bigint;
  v_rows bigint;
BEGIN
  LOOP
    WITH batch AS (
      SELECT *
      FROM okx_raw.trades
      WHERE ts_ingest_ms > v_last
      ORDER BY ts_ingest_ms
      LIMIT 500000
    ),
    ins AS (
      INSERT INTO okx_core.fact_trades_tick (
        inst_id, ts_event, ts_ingest,
        trade_id, trade_px, trade_sz, side
      )
      SELECT
        instid,
        to_timestamp(ts_event_ms / 1000.0),
        to_timestamp(ts_ingest_ms / 1000.0),
        tradeid,
        px,
        sz,
        lower(side)
      FROM batch
      ON CONFLICT (inst_id, trade_id) DO UPDATE
      SET
        ts_event  = EXCLUDED.ts_event,
        ts_ingest = EXCLUDED.ts_ingest,
        trade_px  = EXCLUDED.trade_px,
        trade_sz  = EXCLUDED.trade_sz,
        side      = EXCLUDED.side
      RETURNING 1
    )
    SELECT
      COALESCE((SELECT max(ts_ingest_ms) FROM batch), v_last),
      COALESCE((SELECT count(*) FROM ins), 0)
    INTO v_new_last, v_rows;
    EXIT WHEN v_rows = 0;      -- батч пустой → всё догнали
    v_last := v_new_last;      -- двигаем watermark
  END LOOP;
END $$;


SELECT * FROM okx_core.fact_trades_tick дшьше 10;










UPDATE okx_raw.orderbook_updates 
SET ts_ingest_ms = ts_event_ms 
WHERE ts_ingest_ms IS NULL;

SELECT COUNT(*) as null_count 
FROM okx_raw.orderbook_updates 
WHERE ts_ingest_ms IS NULL;

CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_orderbook_updates_ts_ingest_ms 
ON okx_raw.orderbook_updates(ts_ingest_ms);




ALTER TABLE okx_raw.orderbook_snapshots 
ADD COLUMN IF NOT EXISTS ts_ingest_ms BIGINT;



SELECT *
FROM timescaledb_information.hypertables
WHERE hypertable_schema='okx_raw' AND hypertable_name='orderbook_snapshots';












