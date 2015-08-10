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
    
    let age = Scalar(0)
    var observedValue = -1
    
    let disposable = age.observe { value in
      observedValue = value
    }
    
    XCTAssertEqual(0, observedValue)
    
    age.value = 1
    XCTAssertEqual(1, observedValue)
    
    disposable.dispose()
    
    age.value = 2
    XCTAssertEqual(1, observedValue)
  }
  
  func testFilterMapChain() {
    let scalar = Scalar(2)
    var observedValue = -1
    
    scalar.filter { $0 % 2 == 0 }.map { $0 * 2 }.observe { value in
      observedValue = value
    }
    
    XCTAssertEqual(observedValue, 4)
    
    scalar.value = 3
    XCTAssertEqual(observedValue, 4)

    scalar.value = 4
    XCTAssertEqual(observedValue, 8)
  }
  
  func testLifetime() {
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
}
