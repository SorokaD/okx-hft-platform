-------------------------------------------------------------------------------------------------------------------------------------------------------------------
ssh -N -L 6432:127.0.0.1:6432 okx-hft-timescaledb@167.86.110.201 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o ExitOnForwardFailure=yes
-------------------------------------------------------------------------------------------------------------------------------------------------------------------






SELECT
    inst_id,

    time_bucket('1 second', ts_event) AS ts_bucket,

    count(*)::int4 AS snapshots_cnt,

    avg(mid_px) AS mid_px_avg,

    avg(ask_px_01 - bid_px_01) AS spread_avg,

    avg(
        bid_sz_01 + bid_sz_02 + bid_sz_03 + bid_sz_04 + bid_sz_05 +
        bid_sz_06 + bid_sz_07 + bid_sz_08 + bid_sz_09 + bid_sz_10
    ) AS bid_depth,

    avg(
        ask_sz_01 + ask_sz_02 + ask_sz_03 + ask_sz_04 + ask_sz_05 +
        ask_sz_06 + ask_sz_07 + ask_sz_08 + ask_sz_09 + ask_sz_10
    ) AS ask_depth,

    avg(
        (
            (bid_sz_01 + bid_sz_02 + bid_sz_03 + bid_sz_04 + bid_sz_05 +
             bid_sz_06 + bid_sz_07 + bid_sz_08 + bid_sz_09 + bid_sz_10)
          -
            (ask_sz_01 + ask_sz_02 + ask_sz_03 + ask_sz_04 + ask_sz_05 +
             ask_sz_06 + ask_sz_07 + ask_sz_08 + ask_sz_09 + ask_sz_10)
        )
        /
        NULLIF(
            (bid_sz_01 + bid_sz_02 + bid_sz_03 + bid_sz_04 + bid_sz_05 +
             bid_sz_06 + bid_sz_07 + bid_sz_08 + bid_sz_09 + bid_sz_10)
          +
            (ask_sz_01 + ask_sz_02 + ask_sz_03 + ask_sz_04 + ask_sz_05 +
             ask_sz_06 + ask_sz_07 + ask_sz_08 + ask_sz_09 + ask_sz_10),
        0)
    ) AS imbalance,

    avg(latency_ms) AS latency_avg_ms

FROM okx_core.fact_orderbook_l10_snapshot

GROUP BY
    inst_id,
    ts_bucket

ORDER BY
    ts_bucket;




   
   
SELECT
    ts_event,
    bid_px_01,
    ask_px_01,
    mid_px,
    spread_px
FROM okx_core.fact_orderbook_l10_snapshot
WHERE inst_id = 'BTC-USDT-SWAP'
ORDER BY ts_event
LIMIT 10000



SELECT
    ts_event,
    bid_px_01 AS price,
    bid_sz_01 AS size,
    'bid' AS side
FROM okx_core.fact_orderbook_l10_snapshot
UNION ALL
SELECT
    ts_event,
    ask_px_01,
    ask_sz_01,
    'ask'
FROM okx_core.fact_orderbook_l10_snapshot


















   SELECT min(ts_event), max(ts_event), count(*) 
   FROM okx_core.fact_orderbook_update_level 
   WHERE inst_id = 'BTC-USDT-SWAP';






















