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









--snapshot for anchor_snapshot_ts 2026-03-22 09:59:39.307000+00:00	
select 
	*,
	to_timestamp(ts_event_ms / 1000.0) at time zone 'UTC' as ts_event_utc
from okx_raw.orderbook_snapshots
where instid = 'BTC-USDT-SWAP'
  and ts_event_ms = 1774176906109
  and level <= 10
order by side, level;

--updates anchor_snapshot_ts 2026-03-22 09:59:39.307000+00:00	
select
    *,
    to_timestamp(ts_event_ms / 1000.0) at time zone 'UTC' as ts_event_utc
from okx_raw.orderbook_updates
where instid = 'BTC-USDT-SWAP'
  and ts_event_ms >= 1774173579307
  and ts_event_ms <= 1774173630000
order by ts_event_ms;
	
	
	




[{"size": "59.31", "price": "68780"}, {"size": "0.05", "price": "68778.2"}, {"size": "0.06", "price": "68778.1"}, {"size": "21.73", "price": "68777.1"}, {"size": "4.92", "price": "68777"}, {"size": "9.16", "price": "68776.9"}, {"size": "0.05", "price": "68776.4"}, {"size": "0.05", "price": "68776.3"}, {"size": "0.1", "price": "68776.1"}, {"size": "12.5", "price": "68776"}, {"size": "0.72", "price": "68774.3"}, {"size": "69.8", "price": "68767.4"}, {"size": "0", "price": "68766.3"}, {"size": "1.45", "price": "68763.7"}, {"size": "0.03", "price": "68761.3"}, {"size": "0", "price": "68761.1"}, {"size": "0", "price": "68759.8"}, {"size": "0.74", "price": "68759.6"}, {"size": "14.54", "price": "68758.5"}, {"size": "29.09", "price": "68756.2"}, {"size": "0.01", "price": "68756"}, {"size": "80", "price": "68754.7"}, {"size": "109.11", "price": "68753.7"}, {"size": "80.76", "price": "68752.8"}, {"size": "0", "price": "68752.7"}, {"size": "0", "price": "68752.6"}, {"size": "0.02", "price": "68752.2"}, {"size": "0", "price": "68751.6"}, {"size": "0.4", "price": "68751"}, {"size": "0.22", "price": "68750.4"}, {"size": "18.81", "price": "68750.3"}, {"size": "35.69", "price": "68749.3"}, {"size": "0.05", "price": "68743.1"}, {"size": "0.01", "price": "68737.2"}, {"size": "10.92", "price": "68733"}, {"size": "0", "price": "68723.3"}, {"size": "0", "price": "68723.2"}, {"size": "0", "price": "68723"}]
[{"size": "59.27", "price": "68780"}, {"size": "0.05", "price": "68779.2"}, {"size": "0.05", "price": "68778.1"}, {"size": "0.06", "price": "68777.5"}, {"size": "6.54", "price": "68777.4"}, {"size": "21.72", "price": "68777.1"}, {"size": "0.05", "price": "68776.8"}, {"size": "0.72", "price": "68774.6"}, {"size": "0", "price": "68774.3"}, {"size": "0", "price": "68764.9"}, {"size": "81.47", "price": "68764.4"}, {"size": "11.9", "price": "68764"}, {"size": "0.73", "price": "68763.7"}, {"size": "0.01", "price": "68763"}, {"size": "0.02", "price": "68762.8"}, {"size": "0.72", "price": "68761.7"}, {"size": "163.07", "price": "68761.6"}, {"size": "31.67", "price": "68760.8"}, {"size": "0.03", "price": "68760.7"}, {"size": "0", "price": "68760.6"}, {"size": "0.02", "price": "68759.6"}, {"size": "0.72", "price": "68758.8"}, {"size": "0", "price": "68755.1"}, {"size": "36.36", "price": "68754.7"}, {"size": "189.09", "price": "68754.1"}, {"size": "80.78", "price": "68753.8"}, {"size": "0.02", "price": "68753.7"}, {"size": "0.03", "price": "68752.8"}, {"size": "36.38", "price": "68752.1"}, {"size": "0", "price": "68750.6"}, {"size": "0", "price": "68750.3"}, {"size": "50.8", "price": "68750.2"}, {"size": "0.03", "price": "68745.1"}, {"size": "56.84", "price": "68744.8"}, {"size": "0.04", "price": "68740.7"}, {"size": "108.08", "price": "68738.4"}, {"size": "0.02", "price": "68736.7"}, {"size": "0.01", "price": "68735.8"}, {"size": "141.65", "price": "68735.3"}, {"size": "0", "price": "68723.4"}]






