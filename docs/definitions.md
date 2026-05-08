# Definitions

## Product Terms

- **Portfolio base currency:** currency used to display total portfolio balance. Current direction: USD.
- **Currency rate:** exchange value shown relative to USD, with USD fixed at `1`.
- **Hard widget:** default widget shipped with the app, such as Gold, S&P 500, currencies, expected balance, or fetch progress.
- **Removable hard widget:** default widget that the user can hide from the dashboard.
- **Market widget:** dashboard unit showing a fetched market value and history.
- **Ticker list:** user-managed group of tracked symbols.
- **Holding:** ticker plus user-entered owned amount or shares.
- **Holding balance:** fetched price multiplied by owned amount, converted into the portfolio base currency when needed.
- **Weight:** a holding's share of portfolio value or a user-entered target share.
- **Expected balance:** projection-style portfolio display carried over from the desktop reference.
- **Fetch progress:** visible state for market-data refresh progress.
- **Stale data:** cached market data shown after refresh fails or has not run recently.
- **Last-updated timestamp:** human-facing timestamp derived from cache metadata `fetchedAt`.

## Market Data Terms

- **Provider:** external market-data source. MVP uses `yahoo` only.
- **Provider symbol:** raw symbol used by the provider when it differs from the canonical app symbol. Example: `TLV:1159250` vs `1159250.TA`.
- **Canonical symbol:** trimmed, uppercased symbol used as the app's cache key and UI identifier.
- **Subunit currency:** provider-reported currency expressed in a sub-unit. Yahoo `GBp` is pence, `ILA` is agorot. Both are normalized to the parent ISO currency by dividing the price by `100`.
- **Market quote:** normalized current-price snapshot for a symbol. Shape defined in `contracts.md`.
- **Historical price:** single normalized daily price record (OHLC plus volume) for a symbol.
- **Historical price series:** ordered set of historical prices for a symbol over a logical range and interval.
- **Previous close:** prior trading day's normalized close, derived from the daily history series rather than blindly trusting provider metadata.
- **Dividend event:** dividend amount and pay date. Amount is in the same normalized currency as the quote price.
- **Forex pair symbol:** provider-formatted currency pair. Yahoo `EURUSD=X` means `1 EUR in USD`.
- **Crumb session:** paired Yahoo `Cookie` header and `crumb` token reused for stock chart calls. Cached together for `30 minutes`.

## Cache Terms

- **Local cache metadata:** bookkeeping fields stored alongside cached payloads. Shape defined in `contracts.md`.
- **Cache status:** lifecycle state of a cached entry. One of `fresh`, `stale`, `expired`, `error`.
- **Cache kind:** identifier for the value shape stored next to metadata. One of `market-quote`, `historical-prices`, `currency-rates`, `gold-quote`, `gold-history`, `symbol-widget`.
- **Cache key:** local cache key. Examples: `quote:AAPL`, `history:AAPL:1d:2y`, `currency-rates`, `gold:history`.
- **Schema version:** integer revision of a cache payload's stored shape. Increment when stored value semantics change, not for cosmetic refactors.
- **Cache envelope:** pairing of `metadata` and typed `data` so market facts stay separate from local-storage facts.

## Time Conventions

- **Unix seconds:** used for market timestamps that come from provider chart data and dividend events.
- **Unix milliseconds:** used for local cache bookkeeping (`fetchedAt`, `staleAt`, `expiresAt`, `writtenAt`).

## ID Conventions

No canonical ID conventions are defined yet.

When implementation starts, define IDs here before using them across docs, storage, contracts, or protocols.
