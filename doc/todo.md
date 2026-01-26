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
