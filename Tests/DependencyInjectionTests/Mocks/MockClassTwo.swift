//
//  MockClassTwo.swift
//  DependencyInjection
//
//  Created by Alejandro Melo Domínguez on 30-08-26.
//

import Foundation

protocol MockProtocolTwo: AnyObject {
    var title: String { get }
}

final class MockClassTwo: MockProtocolTwo {
    let title = "MockClassTwo"
}
