//
//  ProfileViewModelProtocol.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Foundation
import OryAuth

enum ProfileViewState {
    
    case sessionLoaded(OrySession)
    case sessionNotLoaded
}

@MainActor
protocol ProfileViewModelProtocol: ObservableObject, Sendable {
    
    var state: ProfileViewState { get }
    var isLoading: Bool { get }

    func onTask() async
    func logout() async
}
