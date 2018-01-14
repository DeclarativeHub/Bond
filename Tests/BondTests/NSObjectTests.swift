//
//  NSObjectTests.swift
//  Bond
//
//  Created by Srdan Rasic on 23/10/2016.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

@testable import Bond
import ReactiveKit
import XCTest

class NSObjectTests: XCTestCase {

    class TestObject: NSObject {
    }
    
    var object: TestObject!

    override func setUp() {
        super.setUp()
        object = TestObject()
    }

    func testBndDeallocated() {
        object.deallocated.expect([.completed], expectation: expectation(description: #function))
        object = nil
        waitForExpectations(timeout: 1)
    }

    func testBndBag() {
        let d1 = SimpleDisposable()
        let d2 = SimpleDisposable()
        object.bag.add(disposable: d1)
        d2.dispose(in: object.bag)
        object = nil
        XCTAssert(d1.isDisposed)
        XCTAssert(d2.isDisposed)
    }
}

class NSObjectKVOTests: XCTestCase {

    class TestObject: NSObject, BindingExecutionContextProvider {

        @objc dynamic var property: Any! = "a"
        @objc dynamic var propertyString: String = "a"

        var bindingExecutionContext: ExecutionContext {
            return .immediate
        }
    }

    var object: TestObject!

    override func setUp() {
        super.setUp()
        object = TestObject()
    }

    func testObservation() {
        let subject = object.reactive.keyPath("property", ofType: String.self)
        subject.expectNext(["a", "b", "c"])
        object.property = "b"
        object.property = "c"
    }

    func testBinding() {
        let subject = object.reactive.keyPath("property", ofType: String.self)
        subject.expectNext(["a", "b", "c"])
        SafeSignal.just("b").bind(to: subject)
        XCTAssert((object.property as! String) == "b")
        SafeSignal.just("c").bind(to: subject)
        XCTAssert((object.property as! String) == "c")
    }

    func testOptionalObservation() {
        let subject = object.reactive.keyPath("property", ofType: Optional<String>.self)
        subject.expectNext(["a", "b", nil, "c"])
        object.property = "b"
        object.property = nil
        object.property = "c"
    }

    func testOptionalBinding() {
        let subject = object.reactive.keyPath("property", ofType: Optional<String>.self)
        subject.expectNext(["a", "b", nil, "c"])
        SafeSignal.just("b").bind(to: subject)
        XCTAssert((object.property as! String) == "b")
        SafeSignal.just(nil).bind(to: subject)
        XCTAssert(object.property == nil)
        SafeSignal.just("c").bind(to: subject)
        XCTAssert((object.property as! String) == "c")
    }

    func testExpectedTypeObservation() {
        let subject = object.reactive.keyPath("property", ofExpectedType: String.self)
        subject.expectNext(["a", "b", "c"])
        object.property = "b"
        object.property = "c"
    }

    func testExpectedTypeBinding() {
        let subject = object.reactive.keyPath("property", ofExpectedType: String.self)
        subject.expectNext(["a", "b", "c"])
        SafeSignal.just("b").bind(to: subject)
        XCTAssert((object.property as! String) == "b")
        SafeSignal.just("c").bind(to: subject)
        XCTAssert((object.property as! String) == "c")
    }

    func testExpectedTypeFailure() {
        let subject = object.reactive.keyPath("property", ofExpectedType: String.self)
        subject.expect([.next("a"), .failed(.notConvertible(""))])
        object.property = 5
    }

    func testExpectedTypeOptionalObservation() {
        let subject = object.reactive.keyPath("property", ofExpectedType: Optional<String>.self)
        subject.expectNext(["a", "b", nil, "c"])
        object.property = "b"
        object.property = nil
        object.property = "c"
    }

    func testExpectedTypeOptionalBinding() {
        let subject = object.reactive.keyPath("property", ofExpectedType: Optional<String>.self)
        subject.expectNext(["a", "b", nil, "c"])
        SafeSignal.just("b").bind(to: subject)
        XCTAssert((object.property as! String) == "b")
        SafeSignal.just(nil).bind(to: subject)
        XCTAssert(object.property == nil)
        SafeSignal.just("c").bind(to: subject)
        XCTAssert((object.property as! String) == "c")
    }

    func testExpectedTypeOptionalFailure() {
        let subject = object.reactive.keyPath("property", ofExpectedType: Optional<String>.self)
        subject.expect([.next("a"), .failed(.notConvertible(""))])
        object.property = 5
    }

    func testDeallocation() {
        let subject = object.reactive.keyPath("property", ofExpectedType: String.self)
        subject.expect([.next("a"), .completed], expectation: expectation(description: #function))
        weak var weakObject = object
        object = nil
        XCTAssert(weakObject == nil)
        waitForExpectations(timeout: 1)
    }

    func testSwift4Observation() {
        object.reactive.keyPath(\.propertyString).expectNext(["a", "b", "c"])
        object.propertyString = "b"
        SafeSignal.just("c").bind(to: object, keyPath: \.propertyString)
        XCTAssert(object.propertyString == "c")
    }
}
