ssh -N -L 6432:127.0.0.1:6432 okx-hft-timescaledb@167.86.110.201 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o ExitOnForwardFailure=yes








BEGIN;

TRUNCATE TABLE okx_mart.agg_ticker_1s;

INSERT INTO okx_mart.agg_ticker_1s (
    inst_id,
    ts_bucket,
    ticks_cnt,

    last_px_min,
    last_px_max,
    last_px_avg,

    bid_px_min,
    bid_px_max,
    bid_px_avg,

    ask_px_min,
    ask_px_max,
    ask_px_avg,

    bid_sz_min,
    bid_sz_max,
    bid_sz_avg,

    ask_sz_min,
    ask_sz_max,
    ask_sz_avg,

    open_24h_min,
    open_24h_max,
    open_24h_avg,

    high_24h_min,
    high_24h_max,
    high_24h_avg,

    low_24h_min,
    low_24h_max,
    low_24h_avg,

    vol_24h_min,
    vol_24h_max,
    vol_24h_avg,

    vol_ccy_24h_min,
    vol_ccy_24h_max,
    vol_ccy_24h_avg
)
SELECT
    inst_id,
    time_bucket('1 second', ts_event) AS ts_bucket,
    count(*)::int4 AS ticks_cnt,

    min(last_px) AS last_px_min,
    max(last_px) AS last_px_max,
    avg(last_px) AS last_px_avg,

    min(bid_px) AS bid_px_min,
    max(bid_px) AS bid_px_max,
    avg(bid_px) AS bid_px_avg,

    min(ask_px) AS ask_px_min,
    max(ask_px) AS ask_px_max,
    avg(ask_px) AS ask_px_avg,

    min(bid_sz) AS bid_sz_min,
    max(bid_sz) AS bid_sz_max,
    avg(bid_sz) AS bid_sz_avg,

    min(ask_sz) AS ask_sz_min,
    max(ask_sz) AS ask_sz_max,
    avg(ask_sz) AS ask_sz_avg,

    min(open_24h) AS open_24h_min,
    max(open_24h) AS open_24h_max,
    avg(open_24h) AS open_24h_avg,

    min(high_24h) AS high_24h_min,
    max(high_24h) AS high_24h_max,
    avg(high_24h) AS high_24h_avg,

    min(low_24h) AS low_24h_min,
    max(low_24h) AS low_24h_max,
    avg(low_24h) AS low_24h_avg,

    min(vol_24h) AS vol_24h_min,
    max(vol_24h) AS vol_24h_max,
    avg(vol_24h) AS vol_24h_avg,

    min(vol_ccy_24h) AS vol_ccy_24h_min,
    max(vol_ccy_24h) AS vol_ccy_24h_max,
    avg(vol_ccy_24h) AS vol_ccy_24h_avg
FROM okx_core.fact_ticker_tick
GROUP BY
    inst_id,
    time_bucket('1 second', ts_event);

COMMIT;