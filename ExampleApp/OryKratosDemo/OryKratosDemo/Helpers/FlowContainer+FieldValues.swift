//
//  FlowContainer+FieldValues.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 27/03/2026.
//

import OryAuth

extension FlowContainer {

    var hiddenFieldValues: [String: String] {
        var values: [String: String] = [:]
        for node in hiddenFields {
            if let value = node.value {
                values[node.name] = value
            }
        }
        return values
    }
}
