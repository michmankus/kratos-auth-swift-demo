//
//  UserFacingOryErrorMapper.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 27/03/2026.
//

import Foundation
import OryAuth

enum UserFacingOryErrorMapper {
    
    // MARK: - Structures

    struct UserFacingError: Sendable {
        
        let message: String?
        let updatedFlow: FlowContainer?
        let action: Action

        init(
            message: String?,
            updatedFlow: FlowContainer? = nil,
            action: Action = .none
        ) {
            self.message = message
            self.updatedFlow = updatedFlow
            self.action = action
        }
    }


    enum Action: Sendable {
        case none
        case reloadFlow
    }

    // MARK: - Public Methods

    static func map(_ error: Error) -> UserFacingError {
        if let oryError = error as? OryError {
            return mapOryError(oryError)
        }
        return UserFacingError(message: error.localizedDescription)
    }

    // MARK: - Private methods

    private static func mapOryError(_ error: OryError) -> UserFacingError {
        switch error {
        case .validation(let updatedFlow):
            let firstError = updatedFlow.messages.first(where: { $0.type == .error })?.text
            return UserFacingError(
                message: firstError,
                updatedFlow: updatedFlow
            )

        case .flowExpired:
            return UserFacingError(
                message: "Form expired. Loading a new one...",
                action: .reloadFlow
            )

        case .network:
            return UserFacingError(message: "Network error. Please check your connection.")

        case .sessionAlreadyAvailable:
            return UserFacingError(message: "You are already logged in.")

        case .missingSessionToken:
            return UserFacingError(message: "Login succeeded but no session was created. Please try again.")
        
        case .keychainError:
            return UserFacingError(message: "Failed retrieving saved session.")

        case .unauthorized:
            return UserFacingError(message: "Unauthorized.")

        case .unknown(_, let message):
            return UserFacingError(message: message ?? "An unexpected error occurred.")
        }
    }
}
