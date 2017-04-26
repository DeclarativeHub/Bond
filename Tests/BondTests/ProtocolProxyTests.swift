//
//  ProtocolProxyTests.swift
//  Bond
//
//  Created by Srdan Rasic on 29/08/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import XCTest
import ReactiveKit
@testable import Bond

@objc protocol TestDelegate: NSObjectProtocol {
  func methodA()
  func methodB(_ object: TestObject)
  func methodC(_ object: TestObject, value: Int)
  func methodD(_ object: TestObject, value: Int) -> NSString
}

class TestObject: NSObject {
  weak var delegate: TestDelegate! = nil

  override init() {
    super.init()
  }

  func callMethodA() {
    delegate.methodA()
  }

  func callMethodB() {
    delegate.methodB(self)
  }

  func callMethodC(_ value: Int) {
    delegate.methodC(self, value: value)
  }

  func callMethodD(_ value: Int) -> NSString {
    return delegate.methodD(self, value: value)
  }
}

class ProtocolProxyTests: XCTestCase {

  var object: TestObject! = nil

  var protocolProxy: ProtocolProxy {
    return object.protocolProxy(for: TestDelegate.self, setter: NSSelectorFromString("setDelegate:"))
  }

  override func setUp() {
    object = TestObject()
  }

  func testDisposing() {
    var callCount = 0
    let stream = protocolProxy.signal(for: #selector(TestDelegate.methodA)) { (stream: PublishSubject1<Int>) in
      callCount += 1
    }

    let disposable = stream.observe { _ in }

    if object.delegate.responds(to: #selector(TestDelegate.methodA)) {
      object.callMethodA()
    }

    disposable.dispose()

    if object.delegate.responds(to: #selector(TestDelegate.methodA)) {
      object.callMethodA()
    }

    XCTAssertEqual(callCount, 1)

    let newDisposable = stream.observe { _ in }

    XCTAssert(object.delegate.responds(to: #selector(TestDelegate.methodA)))

    if object.delegate.responds(to: #selector(TestDelegate.methodA)) {
      object.callMethodA()
    }

    newDisposable.dispose()

    XCTAssert(!object.delegate.responds(to: #selector(TestDelegate.methodA)))
    XCTAssertEqual(callCount, 2)
  }

  func testCallbackA() {
    let stream = protocolProxy.signal(for: #selector(TestDelegate.methodA)) { (stream: PublishSubject1<Int>) in
      stream.next(0)
    }

    stream.expectNext([0, 0])
    object.callMethodA()
    object.callMethodA()
  }

  func testCallbackB() {
    let stream = protocolProxy.signal(for: #selector(TestDelegate.methodB(_:))) { (stream: PublishSubject1<Int>, _: TestObject) in
      stream.next(0)
    }

    stream.expectNext([0, 0])
    object.callMethodB()
    object.callMethodB()
  }

  func testCallbackC() {
    let stream = protocolProxy.signal(for: #selector(TestDelegate.methodC(_:value:))) { (stream: PublishSubject1<Int>, _: TestObject, value: Int) in
      stream.next(value)
    }

    stream.expectNext([10, 20])
    object.callMethodC(10)
    object.callMethodC(20)
  }

  func testCallbackD() {
    let stream = protocolProxy.signal(for: #selector(TestDelegate.methodD(_:value:))) { (stream: PublishSubject1<Int>, _: TestObject, value: Int) -> NSString in
      stream.next(value)
      return "\(value)" as NSString
    }

    stream.expectNext([10, 20])
    XCTAssertEqual(object.callMethodD(10), "10")
    XCTAssertEqual(object.callMethodD(20), "20")
  }
}
