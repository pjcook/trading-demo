//
//  ContentViewModel.swift
//  TradingDemo
//
//  Created by PJ on 12/10/2023.
//

import Combine
import Foundation

public class ContentViewModel: ObservableObject {
    /// Link up the backend systems
    private let tradeSpawner = TradeSpawner()
    private let tradeSystem = TradeSystem()
    private var cancellable: [AnyCancellable] = []
    
    /// The published variables for the UI
    @Published public var trades: [Trade] = []
    @Published public var isRunning: Bool = false
    @Published public var tradesProcessed: Int = 0
    @Published public var companyCount: Int = 0
    
    /// Because this gets updated for every trade do not publish it's results otherwise the UI updates too frequently which could saturate the main thread
    public var tradesSpawned: Int = 0

    public init() {
        self.tradeSpawner
            .publisher
            .sink { value in
                self.tradeSystem.execute_trade(value.0, value.1)
                self.tradesSpawned += 1
            }
            .store(in: &self.cancellable)
        
        self.tradeSystem
            .publisher
            .sink { summary in
                let trades = summary.trades.map(Trade.init)
                let tradesProcessed = summary.transactionCount
                let companyCount = summary.companyCount
                Task { @MainActor in
                    self.trades = trades
                    self.tradesProcessed = tradesProcessed
                    self.companyCount = companyCount
                }
            }
            .store(in: &self.cancellable)
    }
    
    /// Start the system generating trades
    public func start() {
        isRunning = true
        tradeSpawner.start()
    }
    
    /// Stop the system generating trades
    public func stop() {
        isRunning = false
        tradeSpawner.stop()
    }
}

/// ViewModel for the UI to make it easier to render trade data, this could have been pushed into the `TradeSystem`.
public struct Trade: Identifiable {
    public let id: String
    public let value: Int
    
    public init(id: String, value: Int) {
        self.id = id
        self.value = value
    }
    
    private init(_ result: (String, Int)) {
        self.id = result.0
        self.value = result.1
    }
}
