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
    object.bnd_deallocated.expect([.completed], expectation: expectation(description: #function))
    object = nil
    waitForExpectations(timeout: 1)
  }

  func testBndBag() {
    let d1 = SimpleDisposable()
    let d2 = SimpleDisposable()
    object.bnd_bag.add(disposable: d1)
    d2.disposeIn(object.bnd_bag)
    object = nil
    XCTAssert(d1.isDisposed)
    XCTAssert(d2.isDisposed)
  }
}

class NSObjectKVOTests: XCTestCase {

  class TestObject: NSObject {
    dynamic var property: Any! = "a"
  }

  var object: TestObject!

  override func setUp() {
    super.setUp()
    object = TestObject()
  }

  func testObservation() {
    let subject = object.dynamic(keyPath: "property", ofType: String.self)
    subject.expectNext(["a", "b", "c"])
    object.property = "b"
    object.property = "c"
  }

  func testBinding() {
    let subject = object.dynamic(keyPath: "property", ofType: String.self)
    subject.expectNext(["a", "b", "c"])
    Signal1.just("b").bind(to: subject)
    XCTAssert((object.property as! String) == "b")
    Signal1.just("c").bind(to: subject)
    XCTAssert((object.property as! String) == "c")
  }

  func testOptionalObservation() {
    let subject = object.dynamic(keyPath: "property", ofType: Optional<String>.self)
    subject.expectNext(["a", "b", nil, "c"])
    object.property = "b"
    object.property = nil
    object.property = "c"
  }

  func testOptionalBinding() {
    let subject = object.dynamic(keyPath: "property", ofType: Optional<String>.self)
    subject.expectNext(["a", "b", nil, "c"])
    Signal1.just("b").bind(to: subject)
    XCTAssert((object.property as! String) == "b")
    Signal1.just(nil).bind(to: subject)
    XCTAssert(object.property == nil)
    Signal1.just("c").bind(to: subject)
    XCTAssert((object.property as! String) == "c")
  }

  func testExpectedTypeObservation() {
    let subject = object.dynamic(keyPath: "property", ofExpectedType: String.self)
    subject.expectNext(["a", "b", "c"])
    object.property = "b"
    object.property = "c"
  }

  func testExpectedTypeBinding() {
    let subject = object.dynamic(keyPath: "property", ofExpectedType: String.self)
    subject.expectNext(["a", "b", "c"])
    Signal1.just("b").bind(to: subject)
    XCTAssert((object.property as! String) == "b")
    Signal1.just("c").bind(to: subject)
    XCTAssert((object.property as! String) == "c")
  }

  func testExpectedTypeFailure() {
    let subject = object.dynamic(keyPath: "property", ofExpectedType: String.self)
    subject.expect([.next("a"), .failed(.notConvertible(""))])
    object.property = 5
  }

  func testExpectedTypeOptionalObservation() {
    let subject = object.dynamic(keyPath: "property", ofExpectedType: Optional<String>.self)
    subject.expectNext(["a", "b", nil, "c"])
    object.property = "b"
    object.property = nil
    object.property = "c"
  }

  func testExpectedTypeOptionalBinding() {
    let subject = object.dynamic(keyPath: "property", ofExpectedType: Optional<String>.self)
    subject.expectNext(["a", "b", nil, "c"])
    Signal1.just("b").bind(to: subject)
    XCTAssert((object.property as! String) == "b")
    Signal1.just(nil).bind(to: subject)
    XCTAssert(object.property == nil)
    Signal1.just("c").bind(to: subject)
    XCTAssert((object.property as! String) == "c")
  }

  func testExpectedTypeOptionalFailure() {
    let subject = object.dynamic(keyPath: "property", ofExpectedType: Optional<String>.self)
    subject.expect([.next("a"), .failed(.notConvertible(""))])
    object.property = 5
  }

  func testDeallocation() {
    let subject = object.dynamic(keyPath: "property", ofExpectedType: String.self)
    subject.expect([.next("a"), .completed], expectation: expectation(description: #function))
    weak var weakObject = object
    object = nil
    XCTAssert(weakObject == nil)
    waitForExpectations(timeout: 1)
  }
}
