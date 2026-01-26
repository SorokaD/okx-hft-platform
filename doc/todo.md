### 2026-01-26 🔒 TODO: Закрыть вопрос доступа к TimescaleDB / pgbouncer

**Контекст:**

Сейчас подключение к БД идёт **напрямую к внешнему IP сервера** через  **pgbouncer** , без SSH/VPN.

PostgreSQL видит `client_addr = local/docker`, но **pgbouncer доступен из интернета** → это риск.

**Что нужно сделать:**

1. Проверить, на каком порту работает pgbouncer (`6432` / `5432`)
2. Проверить firewall:
   <pre class="overflow-visible! px-0!" data-start="647" data-end="689"><div class="contain-inline-size rounded-2xl corner-superellipse/1.1 relative bg-token-sidebar-surface-primary"><div class="sticky top-[calc(--spacing(9)+var(--header-height))] @w-xl/main:top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>sudo</span><span> ufw status numbered
   </span></span></code></div></div></pre>
3. Выбрать финальную модель доступа:
   * 🔐 SSH tunnel (быстро)
   * 🔐 WireGuard VPN (идеально под okx-hft)
   * 🔐 IP whitelist (временный вариант)
4. Закрыть внешние порты:
   <pre class="overflow-visible! px-0!" data-start="870" data-end="926"><div class="contain-inline-size rounded-2xl corner-superellipse/1.1 relative bg-token-sidebar-surface-primary"><div class="sticky top-[calc(--spacing(9)+var(--header-height))] @w-xl/main:top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>ufw deny 5432/tcp
   ufw deny 6432/tcp
   </span></span></code></div></div></pre>
5. Убедиться, что:
   * без SSH/VPN DBeaver **не подключается**
   * через SSH/VPN — **подключается стабильно**
6. Зафиксировать схему в `okx-hft-ops` (README / diagram)

**Цель:**

👉 БД и pgbouncer  **не торчат в интернет** , доступ только по защищённому каналу.



## 2026-01-26 🧨 TODO: Защитить TimescaleDB от Airflow connection storm

**Проблема:**

Airflow создаёт много коротких DB-соединений → pgbouncer / Postgres ловят таймауты → нестабильные DAG’и.

**Цель:**

Сделать Airflow «вежливым» к БД:

ограничить параллелизм, зафиксировать pooling, исключить session-коннекты.

---

### ✅ 1. Проверить, что Airflow ходит ТОЛЬКО через pgbouncer

* Airflow Connection:
  * host = pgbouncer
  * port = `6432` (НЕ 5432)
* Убедиться, что **ни один DAG не подключается напрямую к Postgres**

---

### ✅ 2. Проверить и зафиксировать настройки pgbouncer

* `pool_mode = transaction`
* `default_pool_size` ≥ ожидаемого параллелизма Airflow
* Проверить:
  <pre class="overflow-visible! px-0!" data-start="917" data-end="957"><div class="contain-inline-size rounded-2xl corner-superellipse/1.1 relative bg-token-sidebar-surface-primary"><div class="sticky top-[calc(--spacing(9)+var(--header-height))] @w-xl/main:top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-sql"><span><span>SHOW</span><span> POOLS;
  </span><span>SHOW</span><span> STATS;
  </span></span></code></div></div></pre>
* Убедиться, что:
  * `cl_waiting = 0`
  * есть `sv_idle`

---

### ✅ 3. Ограничить параллелизм Airflow (обязательно)

В `airflow.cfg` или env:

<pre class="overflow-visible! px-0!" data-start="1101" data-end="1192"><div class="contain-inline-size rounded-2xl corner-superellipse/1.1 relative bg-token-sidebar-surface-primary"><div class="sticky top-[calc(--spacing(9)+var(--header-height))] @w-xl/main:top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-ini"><span><span>[core]</span><span>
</span><span>parallelism</span><span> = </span><span>16</span><span>
</span><span>max_active_tasks_per_dag</span><span> = </span><span>4</span><span>
</span><span>max_active_runs_per_dag</span><span> = </span><span>1</span><span>
</span></span></code></div></div></pre>

👉 Цель: **не более N задач одновременно лезут в БД**

---

### ✅ 4. Ввести Airflow Pool для DB-задач

Создать pool:

<pre class="overflow-visible! px-0!" data-start="1310" data-end="1369"><div class="contain-inline-size rounded-2xl corner-superellipse/1.1 relative bg-token-sidebar-surface-primary"><div class="sticky top-[calc(--spacing(9)+var(--header-height))] @w-xl/main:top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-bash"><span><span>airflow pools </span><span>set</span><span> db_pool 4 </span><span>"Limited DB access"</span><span>
</span></span></code></div></div></pre>

Во всех DAG’ах с БД:

<pre class="overflow-visible! px-0!" data-start="1392" data-end="1420"><div class="contain-inline-size rounded-2xl corner-superellipse/1.1 relative bg-token-sidebar-surface-primary"><div class="sticky top-[calc(--spacing(9)+var(--header-height))] @w-xl/main:top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-python"><span><span>pool=</span><span>"db_pool"</span><span>
</span></span></code></div></div></pre>

👉 Даже при десятках DAG’ов — БД видит максимум 4 задачи.

---

### ✅ 5. Проверить код DAG’ов (PostgresHook)

* ❌ Не держать соединение дольше задачи
* ❌ Не создавать hook глобально
* ✅ Использовать `hook.run()` или `with get_conn():`
* ✅ Один хук = одна логическая операция

---

### ✅ 6. Проверить фактическую нагрузку

В Postgres:

<pre class="overflow-visible! px-0!" data-start="1754" data-end="1852"><div class="contain-inline-size rounded-2xl corner-superellipse/1.1 relative bg-token-sidebar-surface-primary"><div class="sticky top-[calc(--spacing(9)+var(--header-height))] @w-xl/main:top-9"><div class="absolute end-0 bottom-0 flex h-9 items-center pe-2"><div class="bg-token-bg-elevated-secondary text-token-text-secondary flex items-center gap-4 rounded-sm px-2 font-sans text-xs"></div></div></div><div class="overflow-y-auto p-4" dir="ltr"><code class="whitespace-pre! language-sql"><span><span>select</span><span>
  application_name,
  </span><span>count</span><span>(</span><span>*</span><span>)
</span><span>from</span><span> pg_stat_activity
</span><span>group</span><span></span><span>by</span><span></span><span>1</span><span>
</span><span>order</span><span></span><span>by</span><span></span><span>2</span><span></span><span>desc</span><span>;
</span></span></code></div></div></pre>

Ожидание:

* Airflow **не топ-1**
* нет сотен idle / active коннектов

---

### ✅ 7. Финализация

* После фиксов:
  * переподключить Airflow
  * перезапустить scheduler / workers
* Зафиксировать итог:
  * в `okx-hft-ops`
  * как **DB access policy для Airflow**

---

### 🎯 Done = когда

* Airflow DAG’и стартуют **стабильно**
* нет `timeout expired` при подключении
* pgbouncer не уходит в `cl_waiting`
* TimescaleDB перестаёт «задыхаться»
