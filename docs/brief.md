# Money Hero Mobile Brief

## Mission

Money Hero mobile helps a user understand portfolio value and market movement from a phone.

It combines user-entered portfolio data with fetched market data, keeping the experience lightweight, practical, and close to the existing desktop tracker.

## Goals

- Bring the core Money Hero desktop tracker idea to iOS and Android.
- Make current portfolio balance, market movement, and data freshness visible quickly.
- Let users maintain currencies, market widgets, ticker lists, holdings, and weights.
- Keep the mobile experience local-first.
- Adapt desktop behavior to mobile-native screens instead of copying desktop tables directly.

## Non-Goals

- Trading, brokerage integration, or financial advice.
- Account creation, authentication, backend sync, or multi-device sync.
- Buy allocation suggestions.
- Notifications.
- Localization. English only.
- Background data refresh.
- A full PRD, UX spec, implementation plan, or release checklist.

## Direction

### Platform

- Target platform is undecided. Plan to ship three separate MVP apps in sibling folders `swift/` (native iOS), `flutter/` (Flutter iOS+Android), and `react/` (React Native iOS+Android), each tracking the same MVP feature set.
- No backend in MVP. User data is local-only on device.

### Data and refresh

- Use Yahoo Finance for current prices and historical market data.
- Refresh on app open and on pull-to-refresh. No background refresh.
- Offline mode is supported. Show cached latest data with a last-updated timestamp.

### Tracked symbols

- Tracked symbols at launch: S&P 500 and Gold only.
- Hidden desktop symbols `VWRA.L`, `IGLN.L`, `MORE-S7.TA`, `COPX`, `PSI`, `HEAL.L` are not present in mobile.

### Widgets

- Widgets are configurable. Users can hide, show, and reorder.
- Default-enabled widgets: Gold and S&P 500.
- Currency widget defaults to USD, EUR, and GBP. USD is fixed at `1`.
- Total portfolio balance widget renders only when the user has holdings.
- Expected balance widgets render only when the user has holdings.
- Fetch progress widget is always available.

### Currency

- USD is the portfolio base currency.
- USD is fixed at `1` in the currency view.

### Holdings

- Users add and remove tickers in their ticker list.
- Users enter owned shares per holding.
- Users set target weights per holding.
- Users can hide and show holdings within tables.
- Holding balance is computed as fetched price multiplied by owned shares, converted into USD when needed.
- Behavior mirrors the Money Hero desktop tracker.

### Expected balance

- Default widgets: 1-year and 5-year projections.
- User-selectable additional periods: 6 months and 2 years.

### Historical performance

- Fixed period set: 1 month, 6 months, and 2 years. Same as desktop.

### Theming

- Light and dark themes only.

## Source Inputs

- `docs/desktop.png` - desktop reference screenshot.

## Open Questions

See `docs/open-questions.md`.
