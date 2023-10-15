# Trading Demo

A prototype app to demonstrate a high transaction application and one possible solution for managing up to 1 million transactions per second in an iOS app.

In `Debug` mode the system processes about 100,000 trades per second, but in release mode it's between 500,000 to 1,000,000 trades per second depending on the device running the code.

The code has been optimised to use the fewest number of threads, smallest amount of memory and have the smallest CPU overhead it can. 

The `TradeSystem` uses a `buffer` to temporarily store `pendingTrades` so that `locking` of the main data store `trades` is more accessible for being read from the `main thread` as required so as not to block the UI.

## Views

- `ContentView` holds a basic user interface to preview the highest trading companies, and the number of transactions going through the system. There is a start/stop button to start/stop the `TradeSpawner`.

## ViewModel

- `ContentViewModel` is the glue to bind the `TradeSystem`, `TradeSpawner` and `UI` together.

## Services

- `TradeSystem` this is the main data store that processes all new `trades` and publishes reports of the latest highest trading companies.
- `TradeSpawner` this is a test engine that attempts to generate as many `trades per second` as it possibly can.
- `TestData` is a data model used to generate random trades for the `TradeSpawner`.
