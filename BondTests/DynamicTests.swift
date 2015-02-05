//
//  DynamicTests.swift
//  Bond
//
//  Created by Brian Hardy on 1/30/15.
//
//

import UIKit
import XCTest
import Bond

class DynamicTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testValueChangeWithOneListener() {
    let dynamicInt = Dynamic<Int>(0)
    var newValue = NSNotFound
    let intBond = Bond<Int>({ value in
      newValue = value
    })
    dynamicInt.bonds.append(BondBox<Int>(intBond))
    
    // act: change the value to 1
    dynamicInt.value = 1
    
    // assert: newValue should change
    XCTAssertEqual(newValue, 1)
  }
  
  func testValueChangeWithMultipleListeners() {
    let dynamicInt = Dynamic<Int>(0)
    var newValues = [Int]()
    // strong reference bonds to avoid premature dealloc
    var bonds = [Bond<Int>]()
    for i in 0..<10 {
      newValues.append(NSNotFound)
      let bond = Bond<Int>({ value in
        newValues[i] = value
      })
      bonds.append(bond)
      dynamicInt.bonds.append(BondBox<Int>(bond))
    }
    
    // act: change the value to 1
    dynamicInt.value = 1
    
    // assert that all the listeners were notified
    for i in 0..<10 {
      XCTAssertEqual(newValues[i], 1, "New value at index \(i) is incorrect")
    }
  }
  
  func testWeakBondRemoval() {
    
    let dynamic = Dynamic<Int>(0)
    var bond1: Bond<Int>? = Bond<Int>({ v in })
    var bond2: Bond<Int>? = Bond<Int>({ v in })
    
    bond1?.bind(dynamic)
    bond2?.bind(dynamic)

    XCTAssert(dynamic.bonds.count == 2, "Initial bonding unsuccessful")
    
    bond1 = nil
    
    // removal is triggered on next change
    dynamic.value = 1
    
    XCTAssert(dynamic.bonds.count == 1, "Clearing unsuccessful")
  }
}
