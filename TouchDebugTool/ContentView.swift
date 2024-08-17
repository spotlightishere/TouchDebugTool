//
//  ContentView.swift
//  TouchDebugTool
//
//  Created by Spotlight Deveaux on 2024-08-16.
//

import SwiftUI

// https://stackoverflow.com/a/64351862
extension Data {
    init?(hex: String) {
        if hex.isEmpty {
            self.init()
            return
        }
        
        // Remove spaces (for e.g. when copying from a hex editor.)
        let filtered = hex.filter { $0.isWhitespace == false }
        guard filtered.count.isMultiple(of: 2) else {
            return nil
        }

        let chars = filtered.map { $0 }
        let bytes = stride(from: 0, to: chars.count, by: 2)
            .map { String(chars[$0]) + String(chars[$0 + 1]) }
            .compactMap { UInt8($0, radix: 16) }

        guard filtered.count / bytes.count == 2 else { return nil }
        self.init(bytes)
    }
}

struct ContentView: View {
    let touchDebugService = TouchDebugService()
    @State var rawContents: String = ""

    var body: some View {
        VStack {
            TextField("Enter hex", text: $rawContents)
            Button {
                guard let data = Data(hex: rawContents) else {
                    print("Invalid hex!")
                    return
                }

                touchDebugService.write(data)
            } label: {
                Text("Send")
            }
        }
        .padding()
        .onAppear {
            registerService()
            touchDebugService.beginWatching()
        }
    }
}
