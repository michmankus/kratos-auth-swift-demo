//
//  OryNodeMessages.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 26/03/2026.
//

import OryAuth
import SwiftUI

// MARK: - OryNodeMessages

/// Renders a list of ``NodeMessage`` items with appropriate styling per severity.
///
/// Used both at the field level (per-node validation) and at the flow level
/// (global messages from ``FlowContainer/messages``).
///
/// - `.error` messages render in red
/// - `.success` messages render in green
/// - `.info` messages render in secondary style
///
/// ```swift
/// // Field-level messages
/// OryNodeMessages(messages: node.messages)
///
/// // Flow-level messages
/// OryNodeMessages(messages: flow.messages)
/// ```
public struct OryNodeMessages: View {

    public let messages: [NodeMessage]

    public init(messages: [NodeMessage]) {
        self.messages = messages
    }

    public var body: some View {
        ForEach(messages) { message in
            Label {
                Text(message.text)
            } icon: {
                messageIcon(for: message.type)
            }
            .font(.caption)
            .foregroundStyle(color(for: message.type))
        }
    }

    // MARK: - Styling

    private func color(for type: MessageType) -> Color {
        switch type {
        case .error: .red
        case .success: .green
        case .info: .secondary
        }
    }

    @ViewBuilder
    private func messageIcon(for type: MessageType) -> some View {
        switch type {
        case .error:
            Image(systemName: "exclamationmark.circle.fill")
        case .success:
            Image(systemName: "checkmark.circle.fill")
        case .info:
            Image(systemName: "info.circle.fill")
        }
    }
}

// MARK: - Previews

#if DEBUG

#Preview("Error messages") {
    OryNodeMessages(messages: [
        NodeMessage(id: 4000006, text: "The provided credentials are invalid.", type: .error),
        NodeMessage(id: 4000007, text: "Password must be at least 8 characters.", type: .error)
    ])
    .padding()
}

#Preview("Mixed messages") {
    OryNodeMessages(messages: [
        NodeMessage(id: 1010004, text: "An email has been sent to verify your address.", type: .info),
        NodeMessage(id: 1010005, text: "Your account has been created.", type: .success)
    ])
    .padding()
}

#endif
