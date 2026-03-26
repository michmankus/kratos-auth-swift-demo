//
//  OryConfiguration.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Foundation
import OryClient

// MARK: - OryConfiguration

/// Configuration for the Ory Auth SDK.
///
/// Provides the server URL for your Ory Network project.
///
/// ```swift
/// let config = OryConfiguration(
///     serverURL: URL(string: "https://your-project.projects.oryapis.com")!
/// )
/// let client = OryAuthClient(configuration: config)
/// ```
public struct OryConfiguration: Sendable {

    /// The base URL of your Ory Network project.
    ///
    /// Example: `https://your-project.projects.oryapis.com`
    public let serverURL: URL

    public init(serverURL: URL) {
        self.serverURL = serverURL
    }

    /// Creates the generated OryClient API configuration from this SDK configuration.
    func makeAPIConfiguration() -> OryClientAPIConfiguration {
        OryClientAPIConfiguration(basePath: serverURL.absoluteString)
    }
}
