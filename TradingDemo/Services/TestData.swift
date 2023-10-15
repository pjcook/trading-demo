//
//  TestData.swift
//  TradingDemo
//
//  Created by PJ on 12/10/2023.
//

import Foundation

/// TestData is an object to generate random test data. For efficiency it generates lists of fake companies and trades upfront an cycles through these to reduce system overhead. The number of trades and companies are deliberately different so that when stepping through the values different trades will be allocated to different companies.
public struct TestData {
    private let companies = TestData.generateCompanies()
    private let trades = TestData.generateTrades()
    private var companyPointer = 0
    private var tradePointer = 0

    public static let shared = TestData()
    
    private init() {}
    
    public mutating func generateTrade() -> (String, Int) {
        let trade = (companies[companyPointer], trades[tradePointer])
        incrementTradePointer()
        incrementCompanyPointer()
        return trade
    }
    
    private mutating func incrementCompanyPointer() {
        companyPointer += 1
        if companyPointer >= companies.count {
            companyPointer = 0
        }
    }
    
    private mutating func incrementTradePointer() {
        tradePointer += 1
        if tradePointer >= trades.count {
            tradePointer = 0
        }
    }
}

extension TestData {
    static let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ".map(String.init)
    
    static func generateCompanies() -> [String] {
        var companies = [String]()
        
        for _ in (0..<3000) {
            let len = Int.random(in: 0...1) + 3
            var name = ""
            for _ in (0..<len) {
                name += alphabet.randomElement()!
            }
            companies.append(name)
        }
        
        return companies
    }
    
    static func generateTrades() -> [Int] {
        var trades = [Int]()
        
        for _ in (0..<437) {
            trades.append(Int.random(in: -500...500) + 30)
        }
        
        return trades
    }
}

