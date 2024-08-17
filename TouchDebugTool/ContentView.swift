//
//  ContentView.swift
//  TouchDebugTool
//
//  Created by Spotlight Deveaux on 2024-08-16.
//

import SwiftUI

struct ContentView: View {
    let touchDebugService = TouchDebugService()

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            registerService()
            touchDebugService.beginWatching()
        }
    }
}

#Preview {
    ContentView()
}
