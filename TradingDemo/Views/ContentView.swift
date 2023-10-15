//
//  ContentView.swift
//  TradingDemo
//
//  Created by PJ on 12/10/2023.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: ContentViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            List(viewModel.trades) { trade in
                HStack {
                    Text(trade.id)
                    
                    Text(String(trade.value))
                }
            }
            
            Spacer()
            
            Text("Trades spawned: \(viewModel.tradesSpawned)")
            Text("Trades processed: \(viewModel.tradesProcessed)")
            Text("Company count: \(viewModel.companyCount)")
            
            HStack {
                Button(action: toggleTrades) {
                    Text(viewModel.isRunning ? "Stop trades" : "Start trades")
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    private func toggleTrades() {
        if viewModel.isRunning {
            viewModel.stop()
        } else {
            viewModel.start()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ContentViewModel())
}
