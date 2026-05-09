import "market_history_models.dart";
import "market_provider_models.dart";
import "market_quote_models.dart";

enum CacheKind {
  marketQuote("market-quote"),
  historicalPrices("historical-prices"),
  currencyRates("currency-rates"),
  goldQuote("gold-quote"),
  goldHistory("gold-history"),
  symbolWidget("symbol-widget");

  const CacheKind(this.value);
  final String value;
}

enum CacheStatus {
  fresh("fresh"),
  stale("stale"),
  expired("expired"),
  error("error");

  const CacheStatus(this.value);
  final String value;
}

enum CacheSource {
  network("network"),
  cache("cache");

  const CacheSource(this.value);
  final String value;
}

class LocalCacheMetadata {
  const LocalCacheMetadata({
    required this.key,
    required this.kind,
    required this.provider,
    required this.symbol,
    required this.fetchedAt,
    required this.staleAt,
    required this.expiresAt,
    required this.writtenAt,
    required this.status,
    required this.source,
    required this.schemaVersion,
    required this.etag,
    required this.error,
  });

  final String key;
  final CacheKind kind;
  final MarketDataProvider provider;
  final String? symbol;
  final int fetchedAt;
  final int staleAt;
  final int expiresAt;
  final int writtenAt;
  final CacheStatus status;
  final CacheSource source;
  final int schemaVersion;
  final String? etag;
  final String? error;

  LocalCacheMetadata copyWith({
    CacheStatus? status,
    CacheSource? source,
    String? error,
  }) {
    return LocalCacheMetadata(
      key: key,
      kind: kind,
      provider: provider,
      symbol: symbol,
      fetchedAt: fetchedAt,
      staleAt: staleAt,
      expiresAt: expiresAt,
      writtenAt: writtenAt,
      status: status ?? this.status,
      source: source ?? this.source,
      schemaVersion: schemaVersion,
      etag: etag,
      error: error ?? this.error,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        "key": key,
        "kind": kind.value,
        "provider": provider.name,
        "symbol": symbol,
        "fetchedAt": fetchedAt,
        "staleAt": staleAt,
        "expiresAt": expiresAt,
        "writtenAt": writtenAt,
        "status": status.value,
        "source": source.value,
        "schemaVersion": schemaVersion,
        "etag": etag,
        "error": error,
      };

  factory LocalCacheMetadata.fromJson(Map<String, dynamic> json) {
    return LocalCacheMetadata(
      key: json["key"] as String,
      kind: CacheKind.values.firstWhere((kind) => kind.value == json["kind"]),
      provider: MarketDataProvider.values.firstWhere(
        (provider) => provider.name == json["provider"],
      ),
      symbol: json["symbol"] as String?,
      fetchedAt: json["fetchedAt"] as int,
      staleAt: json["staleAt"] as int,
      expiresAt: json["expiresAt"] as int,
      writtenAt: json["writtenAt"] as int,
      status: CacheStatus.values.firstWhere(
        (status) => status.value == json["status"],
      ),
      source: CacheSource.values.firstWhere(
        (source) => source.value == json["source"],
      ),
      schemaVersion: json["schemaVersion"] as int,
      etag: json["etag"] as String?,
      error: json["error"] as String?,
    );
  }
}

class CachedMarketQuote {
  const CachedMarketQuote({required this.metadata, required this.data});

  final LocalCacheMetadata metadata;
  final MarketQuote data;

  Map<String, Object?> toJson() => <String, Object?>{
        "metadata": metadata.toJson(),
        "data": data.toJson(),
      };

  factory CachedMarketQuote.fromJson(Map<String, dynamic> json) {
    return CachedMarketQuote(
      metadata: LocalCacheMetadata.fromJson(json["metadata"] as Map<String, dynamic>),
      data: MarketQuote.fromJson(json["data"] as Map<String, dynamic>),
    );
  }
}

class CachedHistoricalPrices {
  const CachedHistoricalPrices({required this.metadata, required this.data});

  final LocalCacheMetadata metadata;
  final HistoricalPriceSeries data;

  Map<String, Object?> toJson() => <String, Object?>{
        "metadata": metadata.toJson(),
        "data": data.toJson(),
      };

  factory CachedHistoricalPrices.fromJson(Map<String, dynamic> json) {
    return CachedHistoricalPrices(
      metadata: LocalCacheMetadata.fromJson(json["metadata"] as Map<String, dynamic>),
      data: HistoricalPriceSeries.fromJson(json["data"] as Map<String, dynamic>),
    );
  }
}
