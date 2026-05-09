import "dart:convert";
import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:money_hero/app/money_hero_app.dart";
import "package:money_hero/cache/local_json_cache_validation.dart";
import "package:money_hero/cache/local_json_cache_store.dart";
import "package:money_hero/dashboard/dashboard_state.dart";
import "package:money_hero/domain/holdings_models.dart";
import "package:money_hero/domain/market_cache_models.dart";
import "package:money_hero/domain/market_history_models.dart";
import "package:money_hero/domain/market_normalization.dart";
import "package:money_hero/domain/market_provider_models.dart";
import "package:money_hero/domain/market_quote_models.dart";
import "package:money_hero/market_data/market_data_protocols.dart";
import "package:money_hero/market_data/market_fetch_queue.dart";
import "package:money_hero/market_data/market_quote_fetcher.dart";
import "package:money_hero/market_data/market_refresh_coordinator.dart";
import "package:money_hero/market_data/market_refresh_request_planner.dart";
import "package:money_hero/market_data/yahoo_chart_parser.dart";

part "support/fakes.dart";
part "support/model_factories.dart";
part "unit/app_and_domain.dart";
part "unit/cache_and_parser.dart";
part "unit/queue_and_refresh.dart";

void main() {
  registerAppAndDomainTests();
  registerCacheAndParserTests();
  registerQueueAndRefreshTests();
}
