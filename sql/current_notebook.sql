ssh -N -L 6432:127.0.0.1:6432 okx-hft-timescaledb@167.86.110.201 -o ServerAliveInterval=15 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o ExitOnForwardFailure=yes


--------------------------------------------------------------------------------------------
-----------------------------------------for morning----------------------------------------

SELECT
  'fact_funding_rate_event' AS table_name,
  min(ts_event) AS min_ts,
  max(ts_event) AS max_ts
FROM okx_core.fact_funding_rate_event
UNION ALL
SELECT
  'fact_funding_rate_tick',
  min(ts_event),
  max(ts_event)
FROM okx_core.fact_funding_rate_tick
UNION ALL
SELECT
  'fact_index_tick',
  min(ts_event),
  max(ts_event)
FROM okx_core.fact_index_tick
UNION ALL
SELECT
  'fact_mark_price_tick',
  min(ts_event),
  max(ts_event)
FROM okx_core.fact_mark_price_tick
UNION ALL
SELECT
  'fact_open_interest_tick',
  min(ts_event),
  max(ts_event)
FROM okx_core.fact_open_interest_tick
UNION ALL
SELECT
  'fact_orderbook_l10_snapshot',
  min(ts_event),
  max(ts_event)
FROM okx_core.fact_orderbook_l10_snapshot
UNION ALL
SELECT
  'fact_orderbook_snapshot',
  min(ts_event),
  max(ts_event)
FROM okx_core.fact_orderbook_snapshot
UNION ALL
SELECT
  'fact_orderbook_update',
  min(ts_event),
  max(ts_event)
FROM okx_core.fact_orderbook_update
UNION ALL
SELECT
  'fact_ticker_tick',
  min(ts_event),
  max(ts_event)
FROM okx_core.fact_ticker_tick
UNION ALL
SELECT
  'fact_trades_tick',
  min(ts_event),
  max(ts_event)
FROM okx_core.fact_trades_tick
UNION ALL
-- FEAT слой (time-axis = ts_bucket)
SELECT
  'feat_hybrid_10ms',
  min(ts_bucket),
  max(ts_bucket)
FROM okx_feat.feat_hybrid_10ms
ORDER BY table_name;











