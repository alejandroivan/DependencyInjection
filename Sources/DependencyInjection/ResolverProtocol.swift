//
//  ResolverProtocol.swift
//  Created by Alejandro Melo Domínguez on 14-07-24.
//

import Foundation

public protocol ResolverProtocol {

    // MARK: - Definitions

    typealias Creator = () -> AnyObject

    // MARK: - Registration

    /// Registers a service type to be used to resolve an object, using a `Creator` closure.
    /// - Parameters:
    ///   - serviceType: Ths service type (protocol) to be used for resolving an object.
    ///   - creator: The `Creator` closure that's used to create the object and return it
    ///              as the result of `resolve(_:) throws` or ` resolve(_:completion:)`.
    func register<Service>(
        _ serviceType: Service.Type,
        creator: @escaping Creator
    ) throws

    /// Unregisters the creator associated with the specified service type.
    /// - Parameter serviceType: The service type (protocol) to be unregistered.
    /// - Returns: The creator closure that was removed, associated with the service type.
    /// - Throws: An error of type `ResolverError`.
    @discardableResult
    func unregister<Service>(
        _ serviceType: Service.Type
    ) throws -> Creator?

    /// Clears the registration list. Throws `Error.notRegistered` if no registrations are found.
    /// - Returns: The list of `Creator`s removed.
    /// - Throws: An error of type `ResolverError`.
    @discardableResult
    func unregisterAll() throws -> [Creator]

    // MARK: - Resolution

    /// Resolves a `Creator` from the specified service type (protocol) and returns its result.
    /// - Parameter serviceType: The service type (protocol) from which the `Creator` will be resolved.
    /// - Returns: Returns the service implementation (object) that conforms to the
    ///            service type (protocol), by evaluating the creator.
    /// - Throws: An error of type `ResolverError`.
    func resolve<Service>(
        _ serviceType: Service.Type
    ) throws -> Service

    /// Resolves a `Creator` from the specified service type (protocol) and calls
    /// the `completion(_:)` handler with its result, if found, or the associated `Error`.
    /// - Parameters:
    ///   - serviceType: The service type (protocol) from which the `Creator` will be resolved.
    ///   - completion: The completion handler to be called if the resolving is successful, passing a
    ///                 `Result`value containing with the result of the resolution.
    func resolve<Service>(
        _ serviceType: Service.Type,
        completion: @escaping (Result<Service, ResolverError>) -> Void
    )
}
