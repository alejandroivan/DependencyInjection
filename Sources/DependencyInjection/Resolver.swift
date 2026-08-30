//
//  Resolver.swift
//  Created by Alejandro Melo Domínguez on 14-07-24.
//

import Foundation

public final class Resolver: ResolverProtocol, @unchecked Sendable {

    // MARK: - Public Properties

    public static let shared: some ResolverProtocol = Resolver()

    // MARK: - Internal Properties

    let queue = DispatchQueue(label: "Resolver.queue")

    var _creators: [Key: Container] = [:]

    var creators: [Key: Container] {
        get { queue.sync { self._creators }}
        set { queue.async(flags: .barrier) { self._creators = newValue }}
    }

    // Private Methods

    private func findKey<Service>(for serviceType: Service.Type) throws(ResolverError) -> Key {
        try checkProtocol(serviceType)
        guard let key = creators.keys.first(where: { $0.serviceType == serviceType }) else {
            throw .notFound
        }
        return key
    }

    private func checkProtocol<Service>(_ serviceType: Service.Type) throws(ResolverError) {
        guard !(serviceType is AnyClass) else {
            throw .notAProtocol
        }
    }

    private func checkNotExists<Service>(_ serviceType: Service.Type) throws(ResolverError) {
        let keyValuePair = creators.first { key, _ in
            key.serviceType == serviceType
        }
        guard keyValuePair == nil else {
            throw .alreadyRegistered
        }
    }

    // MARK: - Public Methods

    // MARK: Registration

    public func register<Service>(
        _ serviceType: Service.Type,
        creator: @Sendable @escaping () -> AnyObject
    ) throws(ResolverError) {
        try checkProtocol(serviceType)
        try checkNotExists(serviceType)
        let key = Key(serviceType: serviceType)
        let container = Container(creator: creator)
        creators[key] = container
    }

    @discardableResult
    public func unregister<Service>(
        _ serviceType: Service.Type
    ) throws(ResolverError) -> Creator? {
        try checkProtocol(serviceType)
        let key = try findKey(for: serviceType)
        return creators.removeValue(forKey: key)?.creator
    }

    @discardableResult
    public func unregisterAll() throws(ResolverError) -> [Creator] {
        guard !creators.isEmpty else {
            throw .notFound
        }
        let currentCreators = creators
        return currentCreators.compactMap { key, _ in
            creators.removeValue(forKey: key)?.creator
        }
    }

    // MARK: Resolution

    public func resolve<Service>(
        _ serviceType: Service.Type
    ) throws(ResolverError) -> Service {
        try checkProtocol(serviceType)
        let key = try findKey(for: serviceType)

        guard
            let creator = creators[key]?.creator,
            let service = creator() as? Service
        else {
            throw .invalidType
        }

        return service
    }

    public func resolve<Service>(
        _ serviceType: Service.Type,
        completion: @escaping (Result<Service, ResolverError>) -> Void
    ) {
        do {
            let service = try resolve(serviceType)
            completion(.success(service))
        } catch {
            completion(.failure(error))
        }
    }
}

internal extension Resolver {

    // MARK: - Data Types

    struct Key: Hashable, Sendable {
        let serviceType: Any.Type

        func hash(into hasher: inout Hasher) {
            hasher.combine("\(serviceType)")
        }

        static func == (_ lhs: Key, _ rhs: Key) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }

    struct Container: Sendable {
        let creator: Creator
    }
}
