import "package:flutter/material.dart";

enum AppTab {
  dashboard,
  portfolio,
  settings,
}

extension AppTabView on AppTab {
  String get label {
    switch (this) {
      case AppTab.dashboard:
        return "Dashboard";
      case AppTab.portfolio:
        return "Portfolio";
      case AppTab.settings:
        return "Settings";
    }
  }

  IconData get icon {
    switch (this) {
      case AppTab.dashboard:
        return Icons.home;
      case AppTab.portfolio:
        return Icons.pie_chart;
      case AppTab.settings:
        return Icons.settings;
    }
  }
}
