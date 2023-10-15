//
//  TradingDemoApp.swift
//  TradingDemo
//
//  Created by PJ on 12/10/2023.
//

import SwiftUI

@main
struct TradingDemoApp: App {
    let viewModel = ContentViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}
