//
//  MockClassOne.swift
//  DependencyInjection
//
//  Created by Alejandro Melo Domínguez on 30-08-26.
//

import Foundation

protocol MockProtocolOne: AnyObject {
    var title: String { get }
}

final class MockClassOne: MockProtocolOne {
    let title = "MockClassOne"
}
