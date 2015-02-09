//
//  BondTests.swift
//  BondTests
//
//  Created by Brian Hardy on 1/30/15.
//
//

import Foundation
import XCTest
import Bond

class BondTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testBindWithFireDefault() {
    let dynamicInt = Dynamic<Int>(0)
    var newValue = NSNotFound
    let intBond = Bond<Int>({ value in
      newValue = value
    })
    
    // act
    intBond.bind(dynamicInt)
    
    // assert: it should change the value to 0
    XCTAssertEqual(newValue, 0)
    
    // act: change the value to 1
    dynamicInt.value = 1
    
    // assert: it should change again
    XCTAssertEqual(newValue, 1)
  }
  
  func testBindWithOperator() {
    let dynamicInt = Dynamic<Int>(0)
    var newValue = NSNotFound
    let intBond = Bond<Int>({ value in
      newValue = value
    })
    
    // act
    dynamicInt ->> intBond
    
    // assert: it should change the value to 0
    XCTAssertEqual(newValue, 0)
    
    // act: change the value to 1
    dynamicInt.value = 1
    
    // assert: it should change again
    XCTAssertEqual(newValue, 1)
  }
}
