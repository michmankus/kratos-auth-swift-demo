//
//  Closures.swift
//  OryKratosDemo
//
//  Created by Michal Mańkus on 26/03/2026.
//

public typealias Closure = ReturnClosure<Void>
public typealias ReturnClosure<R> = () -> R
public typealias ValueClosure<T> = ValueReturnClosure<T, Void>
public typealias ValueReturnClosure<T, R> = (_ value: T) -> R

public typealias AsyncClosure = AsyncReturnClosure<Void>
public typealias AsyncReturnClosure<T> = () async -> T
public typealias AsyncValueClosure<T> = AsyncValueReturnClosure<T, Void>
public typealias AsyncValueReturnClosure<T, R> = (_ value: T) async -> R

public typealias SendableClosure = SendableReturnClosure<Void>
public typealias SendableReturnClosure<T> = @Sendable () -> T
public typealias SendableValueClosure<T> = SendableValueReturnClosure<T, Void>
public typealias SendableValueReturnClosure<T, R> = @Sendable (_ value: T) -> R
