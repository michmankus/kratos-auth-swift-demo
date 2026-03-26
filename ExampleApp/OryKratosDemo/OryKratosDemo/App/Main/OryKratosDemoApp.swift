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
    
    var body: some Scene {
        WindowGroup {
            RootView(
                viewModel: RootViewModel(authRepository: AppComponents.authRepository)
            )
        }
    }
}
