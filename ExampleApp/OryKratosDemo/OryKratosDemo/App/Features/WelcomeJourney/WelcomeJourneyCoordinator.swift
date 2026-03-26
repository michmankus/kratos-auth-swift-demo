//
//  WelcomeJourneyCoordinator.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Combine
import SwiftUI

enum WelcomeJourneyPage: String, Hashable, Sendable {
    
    case login
    case register
}

final class WelcomeJourneyCoordinator: CoordinatorProtocol {
    
    typealias Page = WelcomeJourneyPage
    
    @Published var path = RouterPath<Page>()
    
    private let onComplete: Closure
    
    // MARK: - Init
    
    init(
        onComplete: @escaping Closure
    ) {
        self.onComplete = onComplete
    }
    
    // MARK: - Routing
    
    func showLogin() {
        presentCover(
            .login,
            withNavigation: true
        )
    }
    
    func showRegister() {
        presentCover(
            .register,
            withNavigation: true
        )
    }
    
    // MARK: - Actions
    
    func didRegister() {
        onComplete()
    }
}
