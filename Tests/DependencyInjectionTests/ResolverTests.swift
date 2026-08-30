import XCTest
@testable import DependencyInjection

final class ResolverTests: XCTestCase, @unchecked Sendable {

    // MARK: - Subject under test

    var mockOne: MockClassOne!
    var mockTwo: MockClassTwo!
    var sut: Resolver!

    // MARK: - Test set up

    override func setUp() {
        super.setUp()
        mockOne = .init()
        mockTwo = .init()
        sut = .init()

        try? sut.register(MockProtocolOne.self) {
            self.mockOne
        }

        try? sut.register(MockProtocolTwo.self) {
            self.mockTwo
        }
    }

    override func tearDown() {
        _ = try? sut.unregisterAll()
        mockOne = nil
        mockTwo = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Tests - ResolverProtocol

    // MARK: register(_:creator:) throws(ResolverError) -> Creator?

    func test_register() throws {
        // Given
        sut.creators = [:]

        // When
        try sut.register(MockProtocolOne.self) {
            self.mockOne
        }

        // Then
        XCTAssertEqual(sut.creators.count, 1)

        let key = try XCTUnwrap(sut.creators.first?.key)
        XCTAssert(key.serviceType == MockProtocolOne.self)

        let container = try XCTUnwrap(sut.creators[key])
        let resolved = container.creator()
        XCTAssert(resolved === mockOne)
    }

    func test_register_Failure_onNotAProtocol() {
        // Given

        // When
        XCTAssertThrowsError(
            try sut.register(MockClassOne.self) { // NOTE: Not a protocol.
                MockClassOne()
            }
        ) { error in
            // Then
            let error = error as? ResolverError
            XCTAssertNotNil(error)
            XCTAssertEqual(error, .notAProtocol)
        }
    }

    func test_register_Failure_onAlreadyRegistered() {
        // Given

        // When
        XCTAssertThrowsError(
            try sut.register(MockProtocolOne.self) {
                self.mockOne
            }
        ) { error in
            // Then
            let error = error as? ResolverError
            XCTAssertNotNil(error)
            XCTAssertEqual(error, .alreadyRegistered)
        }
    }

    // MARK: func unregister(_:) throws(ResolverError) -> Creator?

    func test_unregister() throws {
        // Given
        let expectedCreator = sut.creators.first {
            $0.key.serviceType == MockProtocolTwo.self
        }
        let expectedObject = expectedCreator?.value.creator()

        // When
        let creator = try sut.unregister(MockProtocolTwo.self)

        // Then
        let object = creator?()
        XCTAssertNotNil(object)
        XCTAssert(object === expectedObject)

        XCTAssertFalse(
            sut.creators.contains { key, _ in
                key.serviceType == MockProtocolTwo.self
            },
            "The creator should be removed from the collection."
        )
    }

    func test_unregister_Failure_onNotAProtocol() {
        // Given

        // When
        XCTAssertThrowsError(
            try sut.unregister(MockClassOne.self) // NOTE: Not a protocol.
        ) { error in
            // Then
            let error = error as? ResolverError
            XCTAssertNotNil(error)
            XCTAssertEqual(error, .notAProtocol)
        }
    }

    func test_unregister_Failure_onNotFound() {
        // Given
        sut.creators = [:]

        // When
        XCTAssertThrowsError(
            try sut.unregister(MockProtocolOne.self)
        ) { error in
            // Then
            let error = error as? ResolverError
            XCTAssertNotNil(error)
            XCTAssertEqual(error, .notFound)
        }
    }

    // MARK: func unregisterAll() throws(ResolverError) -> [Creator]

    func test_unregisterAll() throws {
        // Given
        let totalCreators = sut.creators.keys.count

        // When
        let unregisteredCreators = try sut.unregisterAll()

        // Then
        XCTAssertTrue(sut.creators.keys.isEmpty)
        XCTAssertFalse(unregisteredCreators.isEmpty)
        XCTAssertEqual(unregisteredCreators.count, totalCreators)
    }

    func test_unregisterAll_Failure_onEmptyCreators() {
        // Given
        sut.creators = [:]

        // When
        XCTAssertThrowsError(
            try sut.unregisterAll()
        ) { error in
            // Then
            let error = error as? ResolverError
            XCTAssertNotNil(error)
            XCTAssertEqual(error, .notFound)
        }
    }

    // MARK: func resolve(_:) throws(ResolverError) -> Service

    func test_resolve() throws {
        // Given

        // When
        let object = try sut.resolve(MockProtocolOne.self)

        // Then
        XCTAssert(object === mockOne)
    }

    func test_resolve_Failure_onNotAProtocol() {
        // Given

        // When
        XCTAssertThrowsError(
            try sut.resolve(MockClassOne.self)
        ) { error in
            let error = error as? ResolverError
            XCTAssertNotNil(error)
            XCTAssertEqual(error, .notAProtocol)
        }
    }

    func test_resolve_Failure_onNotFound() {
        // Given
        _ = try? sut.unregister(MockProtocolOne.self)

        // When
        XCTAssertThrowsError(
            try sut.resolve(MockProtocolOne.self)
        ) { error in
            let error = error as? ResolverError
            XCTAssertNotNil(error)
            XCTAssertEqual(error, .notFound)
        }
    }

    func test_resolve_Failure_onInvalidObjectClass() throws {
        // Given
        sut.creators = [:]

        try sut.register(MockProtocolOne.self) {
            self.mockTwo // does not conform to `MockProtocolOne`
        }

        // When
        XCTAssertThrowsError(
            try sut.resolve(MockProtocolOne.self)
        ) { error in
            let error = error as? ResolverError
            XCTAssertNotNil(error)
            XCTAssertEqual(error, .invalidType)
        }
    }

    // MARK: func resolve(_:completion:)

    func test_resolveCompletion() {
        // Given
        let exp = expectation(description: #function)

        // When
        sut.resolve(MockProtocolOne.self) { result in
            // Then
            switch result {
            case .success(let object): XCTAssert(object === self.mockOne)
            case .failure: XCTFail("The resolve should succeed.")
            }
            exp.fulfill()
        }

        wait(for: [exp])
    }

    func test_resolveCompletion_Failure_onNotAProtocol() {
        // Given
        let exp = expectation(description: #function)

        // When
        sut.resolve(MockClassOne.self) { result in
            // Then
            switch result {
            case .success: XCTFail("The resolve should fail.")
            case .failure(let error): XCTAssertEqual(error, .notAProtocol)
            }
            exp.fulfill()
        }

        wait(for: [exp])
    }

    func test_resolveCompletion_Failure_onNotFound() {
        // Given
        let exp = expectation(description: #function)
        sut.creators = [:]

        // When
        sut.resolve(MockProtocolOne.self) { result in
            // Then
            switch result {
            case .success: XCTFail("The resolve should fail.")
            case .failure(let error): XCTAssertEqual(error, .notFound)
            }
            exp.fulfill()
        }

        wait(for: [exp])
    }

    func test_resolveCompletion_Failure_onInvalidObjectClass() throws {
        // Given
        let exp = expectation(description: #function)
        sut.creators = [:]

        try sut.register(MockProtocolOne.self) {
            self.mockTwo // does not conform to `MockProtocolOne`
        }

        // When
        sut.resolve(MockProtocolOne.self) { result in
            // Then
            switch result {
            case .success: XCTFail("The resolve should fail.")
            case .failure(let error): XCTAssertEqual(error, .invalidType)
            }
            exp.fulfill()
        }

        wait(for: [exp])
    }
}
