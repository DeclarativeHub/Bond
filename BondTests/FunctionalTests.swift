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
  
  func testMap() {
    let d1 = Dynamic<Int>(0)
    let m = d1.map { "\($0)" }
    
    XCTAssert(m.value == "0", "Initial value")
    XCTAssert(m.faulty == false, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(m.value == "2", "Value after dynamic change")
  }
  
  func testFilter() {
    let d1 = Dynamic<Int>(0)
    let f = d1.filter { $0 > 5 }
    
    var observedValue = -1
    let bond = Bond<Int>() { v in observedValue = v }
    f ->> bond
    
    XCTAssert(f.faulty == true, "Should be faulty")
    XCTAssert(observedValue == -1, "Should not update observed value")
    
    d1.value = 10
    XCTAssert(f.value == 10, "Value after dynamic change")
    XCTAssert(f.faulty == false, "Should not be faulty")
    XCTAssert(observedValue == 10, "Should update observed value")
    
    d1.value = 2
    XCTAssert(f.value == 10, "Value after dynamic change")
    XCTAssert(f.faulty == false, "Should not be faulty")
    XCTAssert(observedValue == 10, "Should update observed value")
  }
  
  func testReduce2() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    
    let r = reduce(d1, d2, *)
    
    XCTAssert(r.value == 2, "Initial value")
    XCTAssert(r.faulty == false, "Should not be faulty")
    
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
    XCTAssert(r.faulty == false, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(r.value == 12, "Value after first dynamic chnage")
    
    d2.value = 3
    XCTAssert(r.value == 18, "Value after second dynamic chnage")
    
    d3.value = 2
    XCTAssert(r.value == 12, "Value after third dynamic chnage")
  }
  
  func testRewrite() {
    let d1 = Dynamic<Int>(0)
    let r = d1.rewrite("foo")
    
    XCTAssert(r.value == "foo", "Initial value")
    XCTAssert(r.faulty == false, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(r.value == "foo", "Value after dynamic change")
  }
  
  func testZip1() {
    let d1 = Dynamic<Int>(0)
    let z = d1.zip("foo")
    
    XCTAssert(z.value.0 == 0 && z.value.1 == "foo", "Initial value")
    XCTAssert(z.faulty == false, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(z.value.0 == 2 && z.value.1 == "foo", "Value after dynamic change")
  }
  
  func testZip2() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    
    let z = d1.zip(d2)
    
    XCTAssert(z.value.0 == 1 && z.value.1 == 2, "Initial value")
    XCTAssert(z.faulty == false, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(z.value.0 == 2 && z.value.1 == 2, "Value after first dynamic chnage")
    
    d2.value = 3
    XCTAssert(z.value.0 == 2 && z.value.1 == 3, "Value after second dynamic chnage")
  }
  
  func testSkip() {
    let d1 = Dynamic<Int>(0)
    let s = d1.skip(1)
    
    var observedValue = -1
    let bond = Bond<Int>() { v in observedValue = v }
    s ->> bond
    
    XCTAssert(s.faulty == true, "Should be faulty")
    XCTAssert(observedValue == -1, "Should not update observed value")
    
    d1.value = 1
    XCTAssert(s.faulty == true, "Should still be faulty")
    XCTAssert(observedValue == -1, "Should not update observed value")
    
    d1.value = 2
    XCTAssert(s.faulty == false, "Should not be faulty")
    XCTAssert(s.value == 2, "Value after dynamic change")
  }
  
  func testAny() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    
    let a = any([d1, d2])
    
    XCTAssert(a.faulty == true, "Should be faulty")
    
    d1.value = 2
    XCTAssert(a.value == 2, "Value after first dynamic chnage")
    XCTAssert(a.faulty == false, "Should not be faulty")
    
    d2.value = 3
    XCTAssert(a.value == 3, "Value after second dynamic chnage")
    XCTAssert(a.faulty == false, "Should not be faulty")
  }
  
  func testFilterMapChain() {
    let d1 = Dynamic<Int>(0)
    let f = d1.filter { $0 > 5 }
    let m = f.map { "\($0)" }
    
    var observedValue = ""
    let bond = Bond<String>() { v in observedValue = v }
    m ->> bond
    
    XCTAssert(f.faulty == true, "Should be faulty")
    XCTAssert(m.faulty == true, "Should be faulty")
    XCTAssert(observedValue == "", "Should not update observed value")
    
    d1.value = 2
    XCTAssert(f.faulty == true, "Should still be faulty")
    XCTAssert(m.faulty == true, "Should still be faulty")
    XCTAssert(observedValue == "", "Should not update observed value")
    
    d1.value = 10
    XCTAssert(f.value == 10, "Value after dynamic change")
    XCTAssert(m.value == "10", "Value after dynamic change")
    XCTAssert(f.faulty == false, "Should not be faulty")
    XCTAssert(m.faulty == false, "Should not be faulty")
    XCTAssert(observedValue == "10", "Should update observed value")
  }
}
