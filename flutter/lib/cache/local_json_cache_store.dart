import "dart:convert";
import "dart:io";

import "../domain/market_cache_models.dart";
import "../market_data/market_data_protocols.dart";
import "local_cache_metadata_status.dart";
import "local_json_cache_validation.dart";

class LocalJsonCacheStore implements MarketCacheStore {
  LocalJsonCacheStore({Directory? directory})
      : _directory = directory ?? Directory("${Directory.systemTemp.path}/money_hero_cache");

  final Directory _directory;

  @override
  Future<void> saveMarketQuote(CachedMarketQuote envelope) async {
    validateCachedMarketQuote(envelope);
    await _writeEnvelope(
      key: envelope.metadata.key,
      kind: CacheKind.marketQuote,
      jsonMap: envelope.toJson(),
    );
  }

  @override
  Future<void> saveHistoricalPrices(CachedHistoricalPrices envelope) async {
    validateCachedHistoricalPrices(envelope);
    await _writeEnvelope(
      key: envelope.metadata.key,
      kind: CacheKind.historicalPrices,
      jsonMap: envelope.toJson(),
    );
  }

  @override
  Future<CachedMarketQuote?> loadMarketQuote({required String key, required int nowMs}) async {
    final File file = _fileFor(key: key, kind: CacheKind.marketQuote);
    if (!await file.exists()) {
      return null;
    }

    try {
      final Map<String, dynamic> jsonMap = await _readJsonMap(file);
      final CachedMarketQuote envelope = CachedMarketQuote.fromJson(jsonMap);
      validateCachedMarketQuote(envelope);
      return envelope.withDerivedStatus(nowMs: nowMs);
    } catch (_) {
      await _removeIfExists(file);
      return null;
    }
  }

  @override
  Future<CachedHistoricalPrices?> loadHistoricalPrices({required String key, required int nowMs}) async {
    final File file = _fileFor(key: key, kind: CacheKind.historicalPrices);
    if (!await file.exists()) {
      return null;
    }

    try {
      final Map<String, dynamic> jsonMap = await _readJsonMap(file);
      final CachedHistoricalPrices envelope = CachedHistoricalPrices.fromJson(jsonMap);
      validateCachedHistoricalPrices(envelope);
      return envelope.withDerivedStatus(nowMs: nowMs);
    } catch (_) {
      await _removeIfExists(file);
      return null;
    }
  }

  Future<void> _writeEnvelope({
    required String key,
    required CacheKind kind,
    required Map<String, Object?> jsonMap,
  }) async {
    await _directory.create(recursive: true);
    final File file = _fileFor(key: key, kind: kind);
    await file.writeAsString(jsonEncode(jsonMap), flush: true);
  }

  Future<Map<String, dynamic>> _readJsonMap(File file) async {
    final Object? decoded = jsonDecode(await file.readAsString());
    return decoded as Map<String, dynamic>;
  }

  Future<void> _removeIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  File _fileFor({required String key, required CacheKind kind}) {
    final String sanitized = key
        .split("")
        .map((char) => RegExp(r"[A-Za-z0-9_-]").hasMatch(char) ? char : "_")
        .join();
    return File("${_directory.path}/${kind.value}_$sanitized.json");
  }
}
