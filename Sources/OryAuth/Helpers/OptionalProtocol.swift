//
//  OptionalProtocol.swift
//  OrySwiftSDK
//
//  Created by Michal Mańkus on 28/03/2026.
//

/// An abstraction for `Optional<Wrapped>`.
public protocol OptionalProtocol: ExpressibleByNilLiteral {

    associatedtype Wrapped

    static var none: Self { get }

    /// Unwraps optional.
    /// - Returns: Unwrapped value.
    func unwrapped() throws -> Wrapped
}
