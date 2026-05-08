# Contracts

Normalized data shapes shared by all three MVP clients (`swift/`, `flutter/`, `react/`). Each client implements these contracts in its own language.

The shapes describe domain data after provider parsing and before persistence, IPC, or UI consumption. Provider response shapes are not contracts; they are an implementation detail of the retrieval protocol in `protocols.md`.

## Contract Ownership

- Cross-client market-data contracts are defined here.
- Provider-specific behavior (endpoints, session handling, retry, freshness) belongs in `protocols.md`.
- Service-specific contracts belong in that service's spec (`../api/spec.md`, `../admin/spec.md`).

## Conventions

- **Symbol:** trimmed, uppercased, length `1-32`. Output is the canonical app symbol.
- **Currency code:** trimmed, uppercased, length `3-8`. Output should normally be a 3-letter ISO currency such as `USD`, `EUR`, or `GBP`. The wider range allows provider non-ISO units to flow through validation pre-normalization.
- **Subunit normalization:** divide by `100` and rewrite the currency code when a provider reports a sub-unit currency (`GBp` -> `GBP`, `ILA` -> `ILS`). Subunits must not survive into the normalized shape.
- **Time:** Unix seconds for market timestamps and dividend dates; Unix milliseconds for local cache bookkeeping.
- **Missing values:** use `null` for unavailable market values. Do not use magic numbers, `0`, or `-1`.
- **Numeric finiteness:** every numeric field is finite. Reject `NaN` and infinities at validation time.

## MarketQuote

Normalized current-price snapshot for a single symbol.

- `symbol` - canonical symbol. Required. Symbol convention above.
- `providerSymbol` - raw provider symbol when it differs from `symbol`. Optional. String, trimmed, length `1-64`.
- `name` - display name. Required. String, trimmed, non-empty. Source order: provider long name, provider short name, then the symbol as fallback.
- `provider` - data source. Required. Enum: `yahoo`. Default `yahoo`.
- `price` - latest normalized quote price. Required. Number, positive, expressed in `currency`.
- `previousClose` - previous trading close. Required. Number, non-negative. Derived from the daily history series, not provider metadata.
- `change` - absolute change. Required. Number. Equals `price - previousClose`.
- `changePercent` - percent change. Required. Number. Equals `(change / previousClose) * 100`. Equals `0` when `previousClose` is `0`.
- `currency` - normalized currency code. Required. Currency convention above.
- `marketTime` - provider market timestamp. Required, nullable. Unix seconds.
- `exchangeTimezoneName` - display/debug timezone. Required, nullable. String, trimmed, non-empty when present.
- `change1m` - percent change versus the closest historical close on or before the one-month anchor. Required, nullable.
- `change6m` - same as `change1m` but for six months. Required, nullable.
- `change1y` - same for one year. Required, nullable.
- `change2y` - same for two years. Required, nullable.
- `dividends` - normalized dividend events. Required. Array of `DividendEvent`. May be empty.

### DividendEvent

- `amount` - dividend amount. Required. Number. Same normalized currency units as the parent quote `price`.
- `date` - pay date. Required. Unix seconds.

## HistoricalPrice

Single daily bar for a symbol.

- `symbol` - canonical symbol. Required.
- `providerSymbol` - raw provider symbol when different. Optional. String, trimmed, length `1-64`.
- `provider` - data source. Required. Enum `yahoo`. Default `yahoo`.
- `currency` - normalized currency. Required.
- `timestamp` - market timestamp. Required. Unix seconds.
- `date` - UTC calendar date for `timestamp`. Required. String matching `YYYY-MM-DD`. Denormalized for cache inspection and chart labels.
- `open` - opening price. Required, nullable. Number.
- `high` - intraday high. Required, nullable. Number.
- `low` - intraday low. Required, nullable. Number.
- `close` - closing price. Required. Number, positive. Required because historical change calculations depend on it.
- `adjustedClose` - dividend/split-adjusted close. Required, nullable. Number.
- `volume` - trade volume. Required, nullable. Integer, non-negative.

## HistoricalPriceSeries

Ordered set of `HistoricalPrice` entries for one symbol.

- `symbol` - canonical symbol. Required.
- `providerSymbol` - raw provider symbol when different. Optional.
- `provider` - data source. Required. Enum `yahoo`. Default `yahoo`.
- `currency` - normalized currency for every price in the series. Required.
- `interval` - bar interval. Required. Enum: `1d`. Intraday is not promised.
- `range` - logical request range. Required. Enum: `1mo`, `6mo`, `1y`, `2y`, `custom`. The retrieval protocol fetches a `2y` window plus padding so all anchors can be derived from one response (see `protocols.md`).
- `prices` - the series. Required. Non-empty array of `HistoricalPrice`.

## LocalCacheMetadata

Bookkeeping fields stored alongside any cached market-data payload.

- `key` - local cache key. Required. String, trimmed, non-empty.
- `kind` - value-shape identifier. Required. Enum: `market-quote`, `historical-prices`, `currency-rates`, `gold-quote`, `gold-history`, `symbol-widget`.
- `provider` - data source. Required. Enum `yahoo`.
- `symbol` - canonical symbol when the entry is symbol-scoped. Required, nullable.
- `fetchedAt` - when the network response was fetched. Required. Unix milliseconds.
- `staleAt` - when UI may still show cached data but should schedule refresh. Required. Unix milliseconds.
- `expiresAt` - when data should be treated as unusable except as offline fallback. Required. Unix milliseconds.
- `writtenAt` - when the local DB write completed. Required. Unix milliseconds.
- `status` - lifecycle state. Required. Enum: `fresh`, `stale`, `expired`, `error`. Derived from current time and last fetch result.
- `source` - origin of the payload being returned. Required. Enum: `network`, `cache`.
- `schemaVersion` - cache payload version. Required. Positive integer.
- `etag` - provider/cache validator. Required, nullable. String, trimmed, non-empty when present. Yahoo chart does not currently provide a useful one; expect `null`.
- `error` - last retrieval error. Required, nullable. String, trimmed, non-empty when present. Set when stale data is being served because a fetch failed.

## Cache Envelopes

Cache payloads must be persisted as `{metadata, data}` envelopes. Mixing cache fields into market objects is not allowed: a quote's `price` means market price, never market price plus cache bookkeeping.

### CachedMarketQuote

- `metadata` - `LocalCacheMetadata` with `kind` fixed to `market-quote`.
- `data` - `MarketQuote`.

### CachedHistoricalPrices

- `metadata` - `LocalCacheMetadata` with `kind` fixed to `historical-prices`.
- `data` - `HistoricalPriceSeries`.

## Validation Notes

- Validate cached payloads against the contract on read. Drop or mark `expired` any entry that fails validation. Never pass malformed data to the UI.
- Validate raw provider responses with provider-specific schemas before normalizing. Provider schemas are an implementation detail of the retrieval protocol and are not contracts.

## Not Yet Defined

- Portfolio snapshot shape. Sync is not in MVP.
- Analytics event shape. Analytics is not in MVP.
- Backend API request/response shapes. No backend in MVP; API shapes belong in `../api/spec.md` once introduced.
