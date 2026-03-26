//
//  Credentials+OryClient.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryClient

// MARK: - Credential → OryClient Body Conversion

/// These extensions bridge the public SDK types to the generated OryClient types.
/// They are the boundary translation layer — kept separate from both the public
/// model definitions (Credentials.swift) and the client logic (OryAuthClient.swift).

extension LoginCredentials {

    /// Convert type-safe credentials to the generated OryClient body type.
    func toUpdateBody() -> UpdateLoginFlowBody {
        switch self {
        case .password(let identifier, let password):
            let body = UpdateLoginFlowWithPasswordMethod(
                identifier: identifier,
                method: "password",
                password: password
            )
            return .typeUpdateLoginFlowWithPasswordMethod(body)

        case .passkey(let response):
            let body = UpdateLoginFlowWithPasskeyMethod(
                method: "passkey",
                passkeyLogin: response
            )
            return .typeUpdateLoginFlowWithPasskeyMethod(body)
        }
    }
}

extension RegistrationCredentials {

    /// Convert type-safe credentials to the generated OryClient body type.
    func toUpdateBody() -> UpdateRegistrationFlowBody {
        switch self {
        case .password(let password, let traits):
            var traitsDict: [String: JSONValue] = [:]
            for (key, value) in traits {
                traitsDict[key] = .string(value)
            }

            let body = UpdateRegistrationFlowWithPasswordMethod(
                method: "password",
                password: password,
                traits: .dictionary(traitsDict)
            )
            return .typeUpdateRegistrationFlowWithPasswordMethod(body)
        }
    }
}
