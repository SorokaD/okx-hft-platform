# OKX Core — Naming & Data Conventions

## Version

v1.0

## Status

Authoritative / Data Contract

---

## 1. Purpose

This document defines mandatory naming rules and data culture for the `okx_core` layer.

Its goals are:

- one semantic meaning → one name → everywhere;
- strict separation of concerns between layers;
- independence from BI tools and ML pipelines;
- predictable, readable, and scalable data model.

Any table, view, materialized view, aggregate, feature set, or mart MUST comply with this document.
If an object does not fit these rules — it MUST NOT be created.

---

## 2. Layer Responsibilities

### okx_raw

Raw data exactly as received from the exchange.

- original field names and types
- timestamps in milliseconds or integers
- JSON blobs allowed
- no guarantees of semantic cleanliness
- immutable

### okx_core

Canonical market truth.

- normalized types
- canonical column names
- all timestamps in UTC timestamptz
- one meaning = one column name
- no BI- or ML-specific logic

### okx_feat (optional)

Machine learning and statistical features.

- explicit horizons and windows
- derived only from okx_core

### okx_mart (optional)

BI / Superset consumption layer.

- business-friendly
- joins allowed
- no raw logic

### okx_health (optional)

Pipeline and data quality monitoring.

---

## 3. Object Naming Rules (okx_core)

### 3.1 Fact Tables

Fact tables represent actual events.

Template:
fact_`<entity>`_`<grain>`

yaml
Копировать код

- entity: trade, index, ticker, mark_price, funding_rate, open_interest, orderbook
- grain: tick, event, snapshot, update

Examples:

- fact_trades_tick
- fact_index_tick
- fact_mark_price_tick
- fact_funding_rate_event
- fact_open_interest_tick
- fact_ticker_tick
- fact_orderbook_snapshot
- fact_orderbook_update

Rules:

- facts contain only events
- no joins
- no features
- no BI logic

---

### 3.2 Aggregated Tables

Template:
agg_`<entity><grain>``<bucket>`

yaml
Копировать код

Examples:

- agg_index_tick_1m
- agg_trades_tick_1s
- agg_mark_price_tick_1m

---

### 3.3 Continuous Aggregates (TimescaleDB)

Template:
cagg_`<entity>`_`<bucket>`

yaml
Копировать код

Examples:

- cagg_index_1m
- cagg_trades_1s

Only aggregations are allowed. No joins, no features.

---

### 3.4 Views

Logical representations without storage.

Template:
v_`<domain>`_`<meaning>`

yaml
Копировать код

Examples:

- v_index_features_1m
- v_index_health_now
- v_orderbook_spread_1m

Views must be deterministic and replaceable.

---

### 3.5 Materialized Views (non-Timescale)

Template:
mv_`<domain><meaning>`<refresh_rule>

yaml
Копировать код

---

## 4. Column Naming Rules

### 4.1 General Rules

- snake_case only
- no ambiguous abbreviations
- physical meaning over visualization convenience
- one semantic meaning → one canonical name

---

## 5. Canonical Column Dictionary

### 5.1 Time

All time in okx_core MUST be UTC timestamptz.

| Meaning                | Column    |
| ---------------------- | --------- |
| exchange event time    | ts_event  |
| ingest / pipeline time | ts_ingest |

Forbidden in okx_core:

- *_ms
- local timezones
- integer timestamps as primary time

---

### 5.2 Identifiers

| Meaning       | Column      |
| ------------- | ----------- |
| instrument id | inst_id     |
| trade id      | trade_id    |
| snapshot id   | snapshot_id |
| checksum      | checksum    |

---

### 5.3 Prices, Sizes, Rates

| Meaning                  | Column            |
| ------------------------ | ----------------- |
| index price              | index_px          |
| mark price               | mark_px           |
| last price               | last_px           |
| bid price                | bid_px            |
| ask price                | ask_px            |
| bid size                 | bid_sz            |
| ask size                 | ask_sz            |
| trade price              | trade_px          |
| trade size               | trade_sz          |
| funding rate             | funding_rate      |
| open interest            | open_interest     |
| open interest (currency) | open_interest_ccy |

All price columns MUST end with `_px`.

---

### 5.4 OHLC Aggregates

| Meaning     | Column    |
| ----------- | --------- |
| open        | open_px   |
| high        | high_px   |
| low         | low_px    |
| close       | close_px  |
| vwap        | vwap_px   |
| event count | event_cnt |

---

### 5.5 Day Reference Levels

| Meaning             | Column      |
| ------------------- | ----------- |
| start of day UTC 00 | sod_utc0_px |
| start of day UTC 08 | sod_utc8_px |

---

## 6. Raw → Core Normalization Rules

Raw naming may differ, but semantic meaning MUST be preserved.

Mandatory conversions:

| okx_raw      | okx_core                    |
| ------------ | --------------------------- |
| instid       | inst_id                     |
| ts_event_ms  | ts_event (timestamptz UTC)  |
| ts_ingest_ms | ts_ingest (timestamptz UTC) |
| idxpx        | index_px                    |
| markpx       | mark_px                     |
| px (trades)  | trade_px                    |
| sz (trades)  | trade_sz                    |
| sodutc0      | sod_utc0_px                 |
| sodutc8      | sod_utc8_px                 |

---

## 7. Fact Table Contract

Every fact table MUST contain:

- inst_id
- ts_event
- ts_ingest

Uniqueness MUST be enforced via:

- primary key, or
- unique index

---

## 8. Decision Checklist (Mandatory)

Before creating ANY object in okx_core, answer:

1. What is the entity?
2. What is the grain?
3. Is this a fact, aggregate, view, feature, or mart?
4. Does the object name follow the template?
5. Are column names canonical?
6. Is time stored as UTC timestamptz?

If any answer is missing — DO NOT CREATE THE OBJECT.

---

## 9. Canonical Mapping of Raw Tables

| okx_raw table       | okx_core fact table     |
| ------------------- | ----------------------- |
| funding_rates       | fact_funding_rate_event |
| index_tickers       | fact_index_tick         |
| mark_prices         | fact_mark_price_tick    |
| tickers             | fact_ticker_tick        |
| trades              | fact_trades_tick        |
| open_interest       | fact_open_interest_tick |
| orderbook_snapshots | fact_orderbook_snapshot |
| orderbook_updates   | fact_orderbook_update   |

---

## 10. Final Principle

Superset dashboards, experiments, and ML models come and go.
`okx_core` is the contract.
The contract does not bend.
