//
//  DisposableTests.swift
//  Bond
//
//  Created by Srđan Rašić on 16/08/15.
//  Copyright © 2015 Bond. All rights reserved.
//

import XCTest
@testable import Bond

private class CountingDisposable: DisposableType {
  var isDisposed: Bool = false
  var disposeCallCount = 0
  
  func dispose() {
    disposeCallCount += 1
    isDisposed = true
  }
  
  init() {}
}

class DisposableTests: XCTestCase {
  
  func testBlockDisposableDisposesAndDisposesOnlyOnce() {
    var executedCount: Int = 0
    let d = BlockDisposable { executedCount += 1 }
    
    XCTAssertFalse(d.isDisposed)
    XCTAssertEqual(executedCount, 0)
    
    d.dispose()
    XCTAssertTrue(d.isDisposed)
    XCTAssertEqual(executedCount, 1)
    
    d.dispose()
    XCTAssertTrue(d.isDisposed)
    XCTAssertEqual(executedCount, 1)
  }
  
  func testSerialDisposableDisposesAndDisposesOnlyOnceAndDisposedImmediatelyIfAlreadyDisposed() {
    let c = CountingDisposable()
    let s = SerialDisposable(otherDisposable: c)
    
    XCTAssertFalse(c.isDisposed)
    XCTAssertFalse(s.isDisposed)
    XCTAssertEqual(c.disposeCallCount, 0)
    
    s.dispose()
    XCTAssertTrue(s.isDisposed)
    XCTAssertTrue(c.isDisposed)
    XCTAssertEqual(c.disposeCallCount, 1)
    
    s.dispose()
    XCTAssertTrue(s.isDisposed)
    XCTAssertTrue(c.isDisposed)
    XCTAssertEqual(c.disposeCallCount, 1)
    
    let c2 = CountingDisposable()
    s.otherDisposable = c2
    
    XCTAssertTrue(s.isDisposed)
    XCTAssertTrue(c2.isDisposed, "Should have been immediately disposed.")
    XCTAssertEqual(c2.disposeCallCount, 1)
  }
  
  func testCompositeDisposableDisposesAndDisposesOnlyOnceAndDisposedImmediatelyIfAlreadyDisposed() {
    let c = CountingDisposable()
    let d = CompositeDisposable([c])
    
    XCTAssertFalse(c.isDisposed)
    XCTAssertFalse(d.isDisposed)
    XCTAssertEqual(c.disposeCallCount, 0)
    
    d.dispose()
    XCTAssertTrue(c.isDisposed)
    XCTAssertTrue(d.isDisposed)
    XCTAssertEqual(c.disposeCallCount, 1)
    
    d.dispose()
    XCTAssertTrue(c.isDisposed)
    XCTAssertTrue(d.isDisposed)
    XCTAssertEqual(c.disposeCallCount, 1)
    
    let c2 = CountingDisposable()
    d.addDisposable(c2)
    
    XCTAssertTrue(d.isDisposed)
    XCTAssertTrue(c2.isDisposed, "Should have been immediately disposed.")
    XCTAssertEqual(c2.disposeCallCount, 1)
    
    d.addDisposable(c2)
    XCTAssertTrue(c2.isDisposed, "Should have been immediately disposed.")
    XCTAssertEqual(c2.disposeCallCount, 2)
  }
  
  func testCompositeDisposableChainDoesNotDeadLock() {
    let d1 = CompositeDisposable()
    let d2 = CompositeDisposable()
    
    d1.addDisposable(d2)
    d1.dispose()
    
    XCTAssert(true, "If we got here, everything is OK!")
  }
}