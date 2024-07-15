//
//  Resolver.swift
//  Created by Alejandro Melo Domínguez on 14-07-24.
//

import Foundation

public final class Resolver: ResolverProtocol {

    // MARK: - Properties

    public static let shared: some ResolverProtocol = Resolver()
    private var creators: [Key: Container] = [:]

    // Private Methods

    private func findKey<Service>(for serviceType: Service.Type) throws -> Key {
        try checkProtocol(serviceType)
        guard let key = creators.keys.first(where: { $0.serviceType == serviceType }) else {
            throw ResolverError.notFound
        }
        return key
    }

    private func checkProtocol<Service>(_ serviceType: Service.Type) throws {
        guard !(serviceType is AnyClass) else {
            throw ResolverError.notAProtocol
        }
    }

    private func checkNotExists<Service>(_ serviceType: Service.Type) throws {
        let keyValuePair = creators.first { key, _ in
            key.serviceType == serviceType
        }
        guard keyValuePair == nil else {
            throw ResolverError.alreadyRegistered
        }
    }

    // MARK: - Public Methods

    // MARK: Registration

    public func register<Service>(
        _ serviceType: Service.Type,
        creator: @escaping () -> AnyObject
    ) throws {
        try checkProtocol(serviceType)
        try checkNotExists(serviceType)
        let key = Key(serviceType: serviceType)
        let container = Container(creator: creator)
        creators[key] = container
    }

    @discardableResult
    public func unregister<Service>(
        _ serviceType: Service.Type
    ) throws -> Creator? {
        try checkProtocol(serviceType)
        let key = try findKey(for: serviceType)
        return creators.removeValue(forKey: key)?.creator
    }

    @discardableResult
    public func unregisterAll() throws -> [Creator] {
        guard !creators.isEmpty else {
            throw ResolverError.notFound
        }
        let currentCreators = creators
        return currentCreators.compactMap { key, _ in
            creators.removeValue(forKey: key)?.creator
        }
    }

    // MARK: Resolution

    public func resolve<Service>(
        _ serviceType: Service.Type
    ) throws -> Service {
        try checkProtocol(serviceType)
        let key = try findKey(for: serviceType)

        guard
            let creator = creators[key]?.creator,
            let service = creator() as? Service
        else {
            throw ResolverError.invalidType
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
        } catch let error as ResolverError {
            completion(.failure(error))
        } catch {
            completion(.failure(.unknown(error: error)))
        }
    }
}

private extension Resolver {

    // MARK: - Data Types

    struct Key: Hashable {
        let serviceType: Any.Type

        func hash(into hasher: inout Hasher) {
            hasher.combine("\(serviceType)")
        }

        static func == (_ lhs: Key, _ rhs: Key) -> Bool {
            lhs.hashValue == rhs.hashValue
        }
    }

    struct Container {
        let creator: Creator
    }
}
