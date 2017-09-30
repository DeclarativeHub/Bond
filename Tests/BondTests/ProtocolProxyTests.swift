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
  func methodE(_ object: TestObject, value: NSIndexPath)
}

class TestObject: NSObject {
  @objc dynamic weak var delegate: TestDelegate! = nil

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

  func callMethodE(_ value: NSIndexPath) {
    return delegate.methodE(self, value: value)
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
    let signal = protocolProxy.signal(for: #selector(TestDelegate.methodA)) { (signal: SafePublishSubject<Int>) in
      callCount += 1
    }

    let disposable = signal.observe { _ in }

    if object.delegate.responds(to: #selector(TestDelegate.methodA)) {
      object.callMethodA()
    }

    disposable.dispose()

    if object.delegate.responds(to: #selector(TestDelegate.methodA)) {
      object.callMethodA()
    }

    XCTAssertEqual(callCount, 1)

    let newDisposable = signal.observe { _ in }

    XCTAssert(object.delegate.responds(to: #selector(TestDelegate.methodA)))

    if object.delegate.responds(to: #selector(TestDelegate.methodA)) {
      object.callMethodA()
    }

    newDisposable.dispose()

    XCTAssert(!object.delegate.responds(to: #selector(TestDelegate.methodA)))
    XCTAssertEqual(callCount, 2)
  }

  func testCallbackA() {
    let signal = protocolProxy.signal(for: #selector(TestDelegate.methodA)) { (subject: SafePublishSubject<Int>) in
      subject.next(0)
    }

    signal.expectNext([0, 0])
    object.callMethodA()
    object.callMethodA()
  }

  func testCallbackB() {
    let signal = protocolProxy.signal(for: #selector(TestDelegate.methodB(_:))) { (subject: SafePublishSubject<Int>, _: TestObject) in
      subject.next(0)
    }

    signal.expectNext([0, 0])
    object.callMethodB()
    object.callMethodB()
  }

  func testCallbackC() {
    let signal = protocolProxy.signal(for: #selector(TestDelegate.methodC(_:value:))) { (subject: SafePublishSubject<Int>, _: TestObject, value: Int) in
      subject.next(value)
    }

    signal.expectNext([10, 20])
    object.callMethodC(10)
    object.callMethodC(20)
  }

  func testCallbackD() {
    let signal = protocolProxy.signal(for: #selector(TestDelegate.methodD(_:value:))) { (subject: SafePublishSubject<Int>, _: TestObject, value: Int) -> String in
      subject.next(value)
      return "\(value)"
    }

    signal.expectNext([10, 20])
    XCTAssertEqual(object.callMethodD(10), "10")
    XCTAssertEqual(object.callMethodD(20), "20")
  }

  func testCallbackE() {
    let signal = protocolProxy.signal(for: #selector(TestDelegate.methodE(_:value:))) { (subject: SafePublishSubject<IndexPath>, _: TestObject, value: IndexPath) in
      subject.next(value)
    }

    signal.expectNext([IndexPath(row: 2, section: 2), IndexPath(row: 3, section: 3)])
    object.callMethodE(NSIndexPath(row: 2, section: 2))
    object.callMethodE(NSIndexPath(row: 3, section: 3))
  }
}
