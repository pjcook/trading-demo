//
//  TradeSpawner.swift
//  TradingDemo
//
//  Created by PJ on 12/10/2023.
//

import Combine
import Foundation

/// TradeSpawner  can be used to spawn and publish a stream of fake trades as quickly as possible. It will randomly generate between 100,000 and 1,000,000 trades before pausing for a short random delay between 1 second and 0.2 seconds
public final class TradeSpawner {
    private var testData: TestData
    private var running = false
    
    // Subscribe to this publisher to receive the stream of trades produced by this system.
    public var publisher: AnyPublisher<(String, Int), Never> {
        subject.eraseToAnyPublisher()
    }
    private var subject = PassthroughSubject<(String, Int), Never>()
    
    public init(testData: TestData = .shared) {
        self.testData = testData
    }
    
    // Start the system firing trades
    public func start() {
        self.running = true
        
        Task.detached {
            self.tick()
        }
    }
    
    // Stop the system firing trades
    public func stop() {
        self.running = false
    }
    
    /// Main heart beat of the system to generate random trades
    /// Decide on a random number of trades to generate
    /// The `autoreleasepool` is there to help clean up test data as it's spawned because we are generating so many test objects
    /// Throw in a random delay between 1 second and 0.2 seconds
    /// Kick off another call to this function so that the system cycles infinitely until the `stop` function is called
    private func tick() {
        guard self.running else { return }
        
        let tradesToSpawn = Int.random(in: 1...10) * 100000
        print("Generating", tradesToSpawn)
        var count = 0
        autoreleasepool {
            while count < tradesToSpawn {
                guard running else { break }
                self.generateTrade()
                count += 1
            }
        }
        
        // include fake delay 1_000_000 == 1 second
        let delay = 1_000_000 * (UInt32.random(in: 1...5) / 10)
        usleep(delay)

        guard self.running else { return }
        Task.detached {
            self.tick()
        }
    }
    
    private func generateTrade() {
        subject.send(self.testData.generateTrade())
    }
}

