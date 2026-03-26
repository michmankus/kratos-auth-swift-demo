//
//  OryKratosDemoApp.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 25/03/2026.
//

import OryAuth
import SwiftUI

@main
struct OryKratosDemoApp: App {

    private let repository: AuthRepository

    init() {
        // TODO: Replace with your Ory Network project URL
        let configuration = OryConfiguration(
            serverURL: URL(string: "https://serene-margulis-6g838kyfne.projects.oryapis.com")!
        )
        if configuration.serverURL.absoluteString == "https://your-project.projects.oryapis.com" {
            fatalError("Setup serverURL before launching the demo app.")
        }
        let client = OryAuthClient(configuration: configuration)
        repository = AuthRepositoryImpl(client: client)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(repository: repository)
        }
    }
}
