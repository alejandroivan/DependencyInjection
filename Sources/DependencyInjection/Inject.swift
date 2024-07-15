//
//  File.swift
//  Created by Alejandro Melo Domínguez on 14-07-24.
//

import Foundation

@propertyWrapper
public final class Inject<Value> {

    // MARK: - Public Properties

    public var wrappedValue: Value? {
        get { getValue() }
        set { _wrappedValue = newValue }
    }

    public var projectedValue: Inject<Value> {
        self
    }

    // MARK: - Private Properties

    private let resolver: ResolverProtocol
    private var _wrappedValue: Value?

    // MARK: - Initialization

    public required init(
        wrappedValue: Value? = nil,
        resolver: ResolverProtocol = Resolver.shared
    ) {
        self._wrappedValue = wrappedValue
        self.resolver = resolver
    }

    // MARK: - Private Methods

    private func getValue() -> Value? {
        if let value = _wrappedValue {
            return value
        } else if let value = try? resolver.resolve(Value.self) {
            _wrappedValue = value
            return value
        } else {
            return nil
        }
    }
}
