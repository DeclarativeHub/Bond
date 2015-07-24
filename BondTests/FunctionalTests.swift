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
    XCTAssert(m.valid == true, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(m.value == "2", "Value after dynamic change")
  }
  
  func testFilter() {
    let d1 = Dynamic<Int>(0)
    let f = d1.filter { $0 > 5 }
    
    var observedValue = -1
    let bond = Bond<Int>() { v in observedValue = v }
    f ->> bond
    
    XCTAssert(f.valid == false, "Should be faulty")
    XCTAssert(observedValue == -1, "Should not update observed value")
    
    d1.value = 10
    XCTAssert(f.value == 10, "Value after dynamic change")
    XCTAssert(f.valid == true, "Should not be faulty")
    XCTAssert(observedValue == 10, "Should update observed value")
    
    d1.value = 2
    XCTAssert(f.value == 10, "Value after dynamic change")
    XCTAssert(f.valid == true, "Should not be faulty")
    XCTAssert(observedValue == 10, "Should update observed value")
  }
  
  func testReduce2() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    
    let r = reduce(d1, dB: d2, f: *)
    
    XCTAssert(r.value == 2, "Initial value")
    XCTAssert(r.valid == true, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(r.value == 4, "Value after first dynamic change")
    
    d2.value = 3
    XCTAssert(r.value == 6, "Value after second dynamic change")
  }
  
  func testReduce3() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    let d3 = Dynamic<Int>(3)
    
    let r = reduce(d1, dB: d2, dC: d3) { $0 * $1 * $2 }
    
    XCTAssert(r.value == 6, "Initial value")
    XCTAssert(r.valid == true, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(r.value == 12, "Value after first dynamic change")
    
    d2.value = 3
    XCTAssert(r.value == 18, "Value after second dynamic change")
    
    d3.value = 2
    XCTAssert(r.value == 12, "Value after third dynamic change")
  }
  
  func testRewrite() {
    let d1 = Dynamic<Int>(0)
    let r = d1.rewrite("foo")
    
    XCTAssert(r.value == "foo", "Initial value")
    XCTAssert(r.valid == true, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(r.value == "foo", "Value after dynamic change")
  }
  
  func testZip1() {
    let d1 = Dynamic<Int>(0)
    let z = d1.zip("foo")
    
    XCTAssert(z.value.0 == 0 && z.value.1 == "foo", "Initial value")
    XCTAssert(z.valid == true, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(z.value.0 == 2 && z.value.1 == "foo", "Value after dynamic change")
  }
  
  func testZip2() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    
    let z = d1.zip(d2)
    
    XCTAssert(z.value.0 == 1 && z.value.1 == 2, "Initial value")
    XCTAssert(z.valid == true, "Should not be faulty")
    
    d1.value = 2
    XCTAssert(z.value.0 == 2 && z.value.1 == 2, "Value after first dynamic change")
    
    d2.value = 3
    XCTAssert(z.value.0 == 2 && z.value.1 == 3, "Value after second dynamic change")
  }
  
  func testSkip() {
    let d1 = Dynamic<Int>(0)
    let s = d1.skip(1)
    
    var observedValue = -1
    let bond = Bond<Int>() { v in observedValue = v }
    s ->> bond
    
    XCTAssert(s.valid == false, "Should be faulty")
    XCTAssert(observedValue == -1, "Should not update observed value")
    
    d1.value = 1
    XCTAssert(s.valid == false, "Should still be faulty")
    XCTAssert(observedValue == -1, "Should not update observed value")
    
    d1.value = 2
    XCTAssert(s.valid == true, "Should not be faulty")
    XCTAssert(s.value == 2, "Value after dynamic change")
  }
  
  func testAny() {
    let d1 = Dynamic<Int>(1)
    let d2 = Dynamic<Int>(2)
    
    let a = any([d1, d2])
    
    XCTAssert(a.valid == false, "Should be faulty")
    
    d1.value = 2
    XCTAssert(a.value == 2, "Value after first dynamic change")
    XCTAssert(a.valid == true, "Should not be faulty")
    
    d2.value = 3
    XCTAssert(a.value == 3, "Value after second dynamic change")
    XCTAssert(a.valid == true, "Should not be faulty")
  }
  
  func testFilterMapChain() {
    var callCount = 0
    let d1 = Dynamic<Int>(0)
    
    let f = d1.filter { $0 > 5 }
    
    let m = f.map { (v: Int) -> String in
      callCount++
      return "\(v)"
    }
    
    XCTAssert(callCount == 0, "Count should be 0 instead of \(callCount)")
    
    var observedValue = ""
    let bond = Bond<String>() { v in observedValue = v }
    m ->> bond
    
    XCTAssert(callCount == 0, "Count should be 0 instead of \(callCount)")
    
    XCTAssert(f.valid == false, "Should be faulty")
    XCTAssert(m.valid == false, "Should be faulty")
    XCTAssert(observedValue == "", "Should not update observed value")
    
    d1.value = 2
    XCTAssert(f.valid == false, "Should still be faulty")
    XCTAssert(m.valid == false, "Should still be faulty")
    XCTAssert(observedValue == "", "Should not update observed value")
    XCTAssert(callCount == 0, "Count should still be 0 instead of \(callCount)")
    
    d1.value = 10
    XCTAssert(f.value == 10, "Value after dynamic change")
    XCTAssert(m.value == "10", "Value after dynamic change")
    XCTAssert(f.valid == true, "Should not be faulty")
    XCTAssert(m.valid == true, "Should not be faulty")
    XCTAssert(observedValue == "10", "Should update observed value")
    XCTAssert(callCount == 1, "Count should be 1 instead of \(callCount)")
  }
  
  func testDeliverOn() {
    let d1 = Dynamic<Int>(0)
    let deliveredOn = deliver(d1, on: dispatch_get_main_queue())
    
    let expectation = expectationWithDescription("Dynamic changed")
    
    let bond = Bond<Int>() { v in
      XCTAssert(v == 10, "Value after dynamic change")
      XCTAssert(NSThread.isMainThread(), "Invalid queue")
      expectation.fulfill()
    }
    
    deliveredOn ->| bond
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
      d1.value = 10
    }
    
    waitForExpectationsWithTimeout(1, handler: nil)
  }

  func testDistinct() {
    var values = [Int]()
    let d1 = Dynamic<Int>(0)
    let bond = Bond<Int>() { v in values.append(v) }

    let distinctD1 = distinct(d1)

    distinctD1 ->> bond

    d1.value = 1
    d1.value = 2
    d1.value = 2
    d1.value = 3
    d1.value = 3
    d1.value = 3

    XCTAssert(values == [0, 1, 2, 3], "Values should equal [0, 1, 2, 3] instead of \(values)")
  }
}
