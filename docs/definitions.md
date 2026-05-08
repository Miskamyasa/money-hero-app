# Definitions

## Terms

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

## ID Conventions

No canonical ID conventions are defined yet.

When implementation starts, define IDs here before using them across docs, storage, contracts, or protocols.
