//
//  TradeSystem.swift
//  TradingDemo
//
//  Created by PJ on 12/10/2023.
//

import Combine
import Foundation

///  `TradeSystem` is the core engine that receives trades, processes them and publishes summary reports of the highest trading companies
public final class TradeSystem {
    /// Queue to manage read/write locking of the `trades` and `transactionCount` internal data
    private let tradesQueue = DispatchQueue(label: "Trades Queue", qos: .userInitiated)
    /// Dictionary to store the processed trade data
    private var trades: [String: Int] = [:]
    /// The number of transactions processed by the system
    private var transactionCount = 0
    /// The number of companies to return in the `summary report`
    private var summaryItemCount = 5

    /// Queue to manage writing to the incoming trades buffer and draining it for processing
    private let processingQueue = DispatchQueue(label: "Processing Queue", qos: .userInitiated)
    /// Array to hold the list of pending trades waiting to be processed
    private var pendingTrades: [(String, Int)] = []
    
    /// Publisher to publish summary report updates, publishing happens each time the `pendingTrades` buffer is drained
    private var subject = PassthroughSubject<TradeSummary, Never>()
    public var publisher: AnyPublisher<TradeSummary, Never> {
        subject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    public init() {
        /// Kick off an infinite loop to continually process pending transactions. Done this way because it's more efficient than using local state variables which require locking/unlocking
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.2) {
            self.processPendingTransactions()
        }
    }
    
    /// Public interface to push a new trade onto the processing queue
    public func execute_trade(_ id: String, _ value: Int) {
        self.processingQueue.async {
            self.pendingTrades.append((id, value))
        }
    }
        
    /// Public interface to allow the number of items in the published summary report to be varied
    public func updateSummaryItemCount(_ count: Int) {
        self.tradesQueue.async {
            self.summaryItemCount = count
        }
    }
        
    /// Public interface to retrieve a report of the latest top `n` trades
    public func print_top_stocks(_ n: Int) -> TradeSummary {
        let group = DispatchGroup()
        group.enter()
        var result: TradeSummary!
        tradesQueue.async {
            result = TradeSummary(
                trades: Array(self.trades
                    .sorted(by: { $0.1 > $1.1 })
                    .prefix(n)
                ),
                transactionCount: self.transactionCount,
                companyCount: self.trades.count
            )
            group.leave()
        }
        
        group.wait()
        return result
    }
}

extension TradeSystem {
    /// The engine that manages processing pending trades
    private func processPendingTransactions() {
        /// The DispatchGroup is used to sequentially process the required workloads on a single thread
        let group = DispatchGroup()
        
        /// Retrieve any `pendingTrades` and drain the buffer
        var pending: [(String, Int)]!
        group.enter()
        processingQueue.async {
            pending = self.pendingTrades
            self.pendingTrades.removeAll()
            group.leave()
        }
        group.wait()
        
        /// Process any `pending` trades
        /// If the system is quiet and there are no `pendingTrades` to process wait longer to give the system a break, this allows the CPU to cool to zero %
        let nextPoll: TimeInterval = pending.isEmpty ? 0.5 : 0.1
        if !pending.isEmpty {
            processPending(pending, in: group)
        }
        
        /// Schedule the next iteraction of this infinite function
        DispatchQueue.global().asyncAfter(deadline: .now() + nextPoll) {
            self.processPendingTransactions()
        }
    }
    
    private func processPending(_ pending: [(String, Int)], in group: DispatchGroup) {
        group.enter()
        tradesQueue.async {
            /// Write all the pending trades to the main data store
            for trade in pending {
                self.processQueuedTrade(trade.0, trade.1)
            }
            
            /// While we're already locking the data store generate a `summary report`
            self.createSummaryAndPublish()
            group.leave()
        }
        group.wait()
    }
    
    /// Make sure this is called on the `tradesQueue` to enforce locking
    private func createSummaryAndPublish() {
        /// Create the summary report to publish
        let summary = TradeSummary(
            trades: Array(self.trades
                .sorted(by: { $0.1 > $1.1 })
                .prefix(self.summaryItemCount)
            ),
            transactionCount: self.transactionCount,
            companyCount: self.trades.count
        )
        
        /// Publish the summary report
        self.subject.send(summary)
    }
    
    /// Function to write the data to the main store and increment the `transactionCount`
    private func processQueuedTrade(_ id: String, _ value: Int) {
        trades[id] = trades[id, default: 0] + value
        transactionCount += 1
    }
}

/// Data model to represent the published summary data
public struct TradeSummary: Equatable {
    public let trades: [(String, Int)]
    public let transactionCount: Int
    public let companyCount: Int
}

extension TradeSummary {
    /// Equatable function
    public static func == (lhs: TradeSummary, rhs: TradeSummary) -> Bool {
        lhs.companyCount == rhs.companyCount
        && lhs.transactionCount == rhs.transactionCount
    }
}

/// Serialization optimised for memory size
extension TradeSystem {
    public func serializeTabDelimited() -> String? {
        let group = DispatchGroup()
        var snapshot: [String : Int] = [:]
        group.enter()
        
        tradesQueue.async {
            snapshot = self.trades
            group.leave()
        }
        group.wait()

        guard !snapshot.isEmpty else { return nil }
        
        var output = ""
        for trade in snapshot {
            output += trade.0 + "\t" + String(trade.1) + "\n"
        }

        return output
    }
    
    public convenience init(tabDelimitedString: String) {
        self.init()
        guard !tabDelimitedString.isEmpty else { return }
        for row in tabDelimitedString.split(separator: "\n", maxSplits: Int.max, omittingEmptySubsequences: true) {
            let elements = row.split(separator: "\t")
            if elements.count >= 2 {
                trades[String(elements[0])] = Int(String(elements[1])) ?? 0
            }
        }
    }
}

