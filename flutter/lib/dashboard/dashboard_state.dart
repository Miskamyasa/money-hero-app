import "dart:async";

import "package:flutter/foundation.dart";

import "../cache/local_json_cache_store.dart";
import "../domain/holdings_models.dart";
import "../market_data/market_fetch_queue.dart";
import "../market_data/market_refresh_coordinator.dart";
import "../market_data/market_refresh_snapshot.dart";

class DashboardState extends ChangeNotifier {
  DashboardState({
    required MarketRefreshCoordinator? coordinator,
    this.holdings = const <Holding>[],
    this.currencySettings = CurrencyWidgetSetting.defaults,
    this.marketTickerSettings = MarketTickerSetting.defaults,
    this.refreshErrorMessage,
  }) : _coordinator = coordinator {
    _observeSnapshots();
  }

  factory DashboardState.live() {
    try {
      return DashboardState(coordinator: MarketRefreshCoordinator(cacheStore: LocalJsonCacheStore()));
    } catch (error) {
      return DashboardState(coordinator: null, refreshErrorMessage: "Cache unavailable: $error");
    }
  }

  final MarketRefreshCoordinator? _coordinator;
  final List<Holding> holdings;
  final CurrencyWidgetSetting currencySettings;
  final MarketTickerSetting marketTickerSettings;
  MarketRefreshSnapshot snapshot = MarketRefreshSnapshot.empty;
  bool isAppOpenLoading = true;
  bool isInitialLoading = false;
  bool isRefreshing = false;
  String? refreshErrorMessage;
  bool _hasStartedAppOpenRefresh = false;
  StreamSubscription<MarketRefreshSnapshot>? _snapshotSubscription;

  bool get hasHoldings => holdings.any((Holding h) => !h.isHidden);

  Future<void> refreshOnAppOpen() async {
    if (_hasStartedAppOpenRefresh) {
      return;
    }
    _hasStartedAppOpenRefresh = true;
    isAppOpenLoading = true;
    notifyListeners();
    await _refresh((MarketRefreshCoordinator coordinator) {
      return coordinator.refreshOnAppOpen(
        holdings: holdings,
        currencySettings: currencySettings,
        marketTickerSettings: marketTickerSettings,
      );
    });
  }

  Future<void> refreshOnPullToRefresh() {
    return _refresh((MarketRefreshCoordinator coordinator) {
      return coordinator.refreshOnPullToRefresh(
        holdings: holdings,
        currencySettings: currencySettings,
        marketTickerSettings: marketTickerSettings,
      );
    });
  }

  Future<void> _refresh(Future<void> Function(MarketRefreshCoordinator coordinator) operation) async {
    if (isRefreshing) {
      return;
    }
    if (_coordinator == null) {
      refreshErrorMessage ??= "Market data is unavailable.";
      isInitialLoading = false;
      isRefreshing = false;
      isAppOpenLoading = false;
      notifyListeners();
      return;
    }
    isRefreshing = true;
    isInitialLoading = snapshot.quotesBySymbol.isEmpty && snapshot.historiesBySymbol.isEmpty;
    refreshErrorMessage = null;
    notifyListeners();
    await operation(_coordinator!);
  }

  void _observeSnapshots() {
    if (_coordinator == null) {
      return;
    }
    _snapshotSubscription = _coordinator!.snapshots().listen((MarketRefreshSnapshot value) {
      snapshot = value;
      refreshErrorMessage = value.refreshErrorMessage ??
          value.quotesBySymbol.values.where((e) => e.metadata.error != null).map((e) => e.metadata.error).cast<String?>().firstWhere((_) => true, orElse: () => null);
      _applyProgress(value.progress);
      notifyListeners();
    });
  }

  void _applyProgress(MarketFetchQueueProgress progress) {
    if (progress.isActive) {
      isRefreshing = true;
      return;
    }
    isRefreshing = false;
    isInitialLoading = false;
    isAppOpenLoading = false;
  }

  @override
  void dispose() {
    _snapshotSubscription?.cancel();
    super.dispose();
  }
}
