//
//  File.swift
//  Created by Alejandro Melo Domínguez on 14-07-24.
//

import Foundation

public enum ResolverError: LocalizedError {
    case alreadyRegistered
    case invalidType
    case notAProtocol
    case notFound
    case unknown(error: Swift.Error)

    public var errorDescription: String? {
        switch self {
        case .alreadyRegistered: "The specified service type (protocol) already has a registration."
        case .invalidType: "The resolved instance does not conform to the specified service type (protocol)."
        case .notAProtocol: "The specified service type is not a protocol, but a class."
        case .notFound: "There's no registered instance for the specified service type (protocol)."
        case .unknown(let error): "An unknown error has been encountered: \(error)"
        }
    }
}
