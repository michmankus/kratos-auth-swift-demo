//
//  LoginViewModelProtocol.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

import Foundation
import OryAuth

@MainActor
protocol LoginViewModelProtocol: ObservableObject, Sendable {
    var flow: FlowContainer? { get }
    var fieldValues: [String: String] { get set }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func loadFlow() async
    func submit() async
    func dismiss()
}
