//
//  File.swift
//  Created by Alejandro Melo Domínguez on 14-07-24.
//

import Foundation

@propertyWrapper
public struct Inject<Value> {

    // MARK: - Public Properties

    public var wrappedValue: Value {
        get {
            guard let value = injector.wrappedValue else {
                preconditionFailure("Cannot resolve an object of type `\(Value.self)`. Have you registered it?")
            }
            return value
        }

        set {
            injector.wrappedValue = newValue
        }
    }

    public var projectedValue: SafeInject<Value> {
        injector.projectedValue
    }

    // MARK: - Private Properties

    private var injector: SafeInject<Value>

    // MARK: - Initialization

    public init(wrappedValue: Value) {
        injector = SafeInject(wrappedValue: wrappedValue)
    }

    public init(wrappedValue: Value? = nil) {
        injector = SafeInject(wrappedValue: wrappedValue)
    }
}
