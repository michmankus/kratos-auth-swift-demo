//
//  OryUI.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

/// Ready-to-use SwiftUI components for rendering Ory Kratos authentication flows.
///
/// `OryUI` provides drop-in UI components that dynamically render forms
/// from ``OryAuth/FlowContainer`` nodes. Import this module for a quick
/// MVP or as a starting point — most apps will implement custom UI while
/// using OryAuth's headless API directly.
///
/// ```swift
/// import OryAuth
/// import OryUI
///
/// struct MyLoginView: View {
///     let flow: FlowContainer
///     @State var fieldValues: [String: String] = [:]
///
///     var body: some View {
///         Form {
///             OryFlowForm(flow: flow, fieldValues: $fieldValues) {
///                 Button("Sign in") { /* submit */ }
///             }
///         }
///     }
/// }
/// ```
public enum OryUI {
    public static let version = "0.1.0"
}
