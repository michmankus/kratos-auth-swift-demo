//
//  ContentView.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 25/03/2026.
//

import OryAuth
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            Text("Ory Auth version: \(OryAuth.version)")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
