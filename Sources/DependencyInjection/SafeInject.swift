//
//  SafeInject.swift
//  DependencyInjection
//
//  Created by Alejandro Melo Domínguez on 07-10-24.
//

import Foundation

@propertyWrapper
public struct SafeInject<Value> {

    // MARK: - Public Properties

    public var wrappedValue: Value? {
        get { getWrappedValue() }
        set { _wrappedValue = newValue }
    }

    public var projectedValue: SafeInject<Value> {
        self
    }

    // MARK: - Private Properties

    private var _wrappedValue: Value?
    private let resolver: ResolverProtocol

    // MARK: - Initialization

    public init(wrappedValue: Value, resolver: ResolverProtocol = Resolver.shared) {
        self._wrappedValue = wrappedValue
        self.resolver = resolver
    }

    public init(wrappedValue: Value? = nil, resolver: ResolverProtocol = Resolver.shared) {
        self._wrappedValue = wrappedValue
        self.resolver = resolver
    }

    // MARK: - Private Methods

    private func getWrappedValue() -> Value? {
        _wrappedValue ?? (try? resolver.resolve(Value.self))
    }
}
