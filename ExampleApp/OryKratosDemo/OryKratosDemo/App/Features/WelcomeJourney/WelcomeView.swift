//
//  WelcomeView.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import SwiftUI

struct WelcomeView: View {
    
    @State var onLoginAction: Closure
    @State var onRegisterAction: Closure
    
    var body: some View {
        VStack {
            Spacer()
            loginButton
            registerButton
            Spacer()
        }
    }
    
    private var loginButton: some View {
        Button("Login") {
            onLoginAction()
        }
        .padding()
    }
    
    private var registerButton: some View {
        Button("Register") {
            onRegisterAction()
        }
        .padding()
    }
}
