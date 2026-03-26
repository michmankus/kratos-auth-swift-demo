//
//  AppComponents.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import Foundation

@MainActor
final class AppComponents: Sendable { }

// MARK: - Ory

extension AppComponents {
    
    private static let oryConfiguration = OryConfiguration(
        serverURL: URL(string: "https://serene-margulis-6g838kyfne.projects.oryapis.com")!
    )
    fileprivate static let oryClient = {
        let configuration = AppComponents.oryConfiguration
        guard configuration.serverURL.absoluteString != "https://your-project.projects.oryapis.com" else {
            fatalError("Setup serverURL before launching the demo app.")
        }
        
        return OryAuthClient(configuration: AppComponents.oryConfiguration)
    }()
}

// MARK: - Repositories

extension AppComponents {

    static let authRepository: AuthRepository = AuthRepositoryImpl(client: AppComponents.oryClient)
}
