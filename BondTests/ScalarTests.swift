//
//  ScalarTests.swift
//  Bond
//
//  Created by Srđan Rašić on 22/07/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import Bond

class ScalarTests: XCTestCase {

  func testObservingAndDisposing() {
    let age = Scalar(2)
    
    age.set(1)
    age.set(0)
    
    var observedValue = -1
    var numberOfInitialReplays = 0
    
    let disposable = age.observe { value in
      observedValue = value
      numberOfInitialReplays++
    }
    
    XCTAssertEqual(1, numberOfInitialReplays)
    XCTAssertEqual(0, observedValue)
    
    age.value = 1
    XCTAssertEqual(1, observedValue)
    
    age.set(2)
    XCTAssertEqual(2, observedValue)
    
    disposable.dispose()
    
    age.value = 3
    XCTAssertEqual(2, observedValue)
  }
  
  func testFilterMapChain() {
    let scalar = Scalar(2)
    var observedValue = -1
    
    scalar
      .filter { $0 % 2 == 0 }
      .map { $0 * 2 }
      .observe { value in
        observedValue = value
      }
    
    XCTAssertEqual(observedValue, 4)
    
    scalar.value = 3
    XCTAssertEqual(observedValue, 4)

    scalar.value = 4
    XCTAssertEqual(observedValue, 8)
  }
  
  func testDisposesOnReleasingEvenThoughBeingObserved() {
    var scalar: Scalar<Int>! = Scalar(0)
    weak var scalarWeak: Scalar<Int>! = scalar
    
    let disposable = scalar.observe { v in }
    
    XCTAssertNotNil(scalarWeak)
    XCTAssertFalse(disposable.isDisposed)
    
    scalar = nil
    XCTAssertNil(scalarWeak)
    XCTAssertTrue(disposable.isDisposed)
  }
  
  func testDisposesOnReleasingEvenThoughBeingBound() {
    let srcScalar: Scalar<Int> = Scalar(0)
    
    var dstScalar: Scalar<Int>! = Scalar(0)
    weak var dstScalarWeak: Scalar<Int>! = dstScalar
    
    let disposable = srcScalar.bindTo(dstScalar)
    
    XCTAssertNotNil(dstScalarWeak)
    XCTAssertFalse(disposable.isDisposed)
    
    dstScalar = nil
    XCTAssertNil(dstScalarWeak)
    XCTAssertTrue(disposable.isDisposed)
  }
  
  func testNotRetainedByCreatedSinkAndDisposesGivenDisposableOnDeinit() {
    var scalar: Scalar<Int>! = Scalar(0)
    weak var scalarWeak: Scalar<Int>! = scalar
    let disposable = SimpleDisposable()
    
    let sink: (Int -> ())? = scalar.sink(disposable)
    
    XCTAssert(sink != nil)
    XCTAssertNotNil(scalarWeak)
    XCTAssertFalse(disposable.isDisposed)
    
    scalar = nil
    XCTAssertNil(scalarWeak)
    XCTAssertTrue(disposable.isDisposed)
  }
}
