//
//  AppState.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Foundation
import OryAuth

public enum AppState: Hashable, Equatable {
    case idle
    case loadingInitialState
    case loggedIn
    case loggedOut
}
