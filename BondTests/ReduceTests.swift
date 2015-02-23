//
//  ReduceTests.swift
//  Bond
//
//  Created by Srdan Rasic on 23/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class ReduceTests: XCTestCase {
  
  func testReduce2() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    
    let r = reduce(d1, d2, *)
    
    XCTAssert(r.value == 2, "Initial value")
    
    d1.value = 2
    XCTAssert(r.value == 4, "Value after first dynamic chnage")
    
    d2.value = 3
    XCTAssert(r.value == 6, "Value after second dynamic chnage")
  }
  
  func testReduce3() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    let d3 = Dynamic<Int>(3)
    
    let r = reduce(d1, d2, d3) { $0 * $1 * $2 }
    
    XCTAssert(r.value == 6, "Initial value")
    
    d1.value = 2
    XCTAssert(r.value == 12, "Value after first dynamic chnage")
    
    d2.value = 3
    XCTAssert(r.value == 18, "Value after second dynamic chnage")
    
    d3.value = 2
    XCTAssert(r.value == 12, "Value after third dynamic chnage")

  }
}
