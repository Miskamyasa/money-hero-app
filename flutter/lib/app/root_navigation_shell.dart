import "package:flutter/material.dart";

import "app_tab.dart";
import "../dashboard/dashboard_state.dart";
import "../dashboard/dashboard_view.dart";
import "placeholder_views.dart";

class RootNavigationShell extends StatefulWidget {
  const RootNavigationShell({super.key});

  @override
  State<RootNavigationShell> createState() => _RootNavigationShellState();
}

class _RootNavigationShellState extends State<RootNavigationShell> {
  AppTab _selectedTab = AppTab.dashboard;
  late final DashboardState _dashboardState;

  @override
  void initState() {
    super.initState();
    _dashboardState = DashboardState.live();
  }

  @override
  void dispose() {
    _dashboardState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedTab.index,
        children: <Widget>[
          DashboardView(state: _dashboardState),
          const PortfolioPlaceholderView(),
          const SettingsPlaceholderView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab.index,
        items: AppTab.values
            .map(
              (tab) => BottomNavigationBarItem(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
        onTap: (index) {
          setState(() {
            _selectedTab = AppTab.values[index];
          });
        },
      ),
    );
  }
}
