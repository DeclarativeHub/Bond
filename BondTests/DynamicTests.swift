//
//  DynamicTests.swift
//  Bond
//
//  Created by Brian Hardy on 1/30/15.
//
//

import Foundation
import XCTest
import Bond

class DynamicTests: XCTestCase {
  
  func testValueChangeWithOneListener() {
    let dynamicInt = Dynamic<Int>(0)
    var newValue = NSNotFound
    
    let intBond = Bond<Int> { value in
      newValue = value
    }
    
    dynamicInt.bindTo(intBond)
    
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
      dynamicInt.bindTo(bond)
    }
    
    // act: change the value to 1
    dynamicInt.value = 1
    
    // assert that all the listeners were notified
    for i in 0..<10 {
      XCTAssertEqual(newValues[i], 1, "New value at index \(i) is incorrect")
    }
  }

  func testConsecutiveBonding() {
    let dynamicInt = Dynamic<Int>(0)

    var counter = 0
    let intBond = Bond<Int>({ value in
      counter++
    })

    // strong reference bonds to avoid premature dealloc
    dynamicInt ->| intBond
    dynamicInt ->| intBond
    dynamicInt ->| intBond

    // act: change the value to 1
    dynamicInt.value = 1

    // assert that all the listeners were notified
    XCTAssert(counter == 1, "Bond called more than once")
  }
  
  func testWeakBondRemoval() {
    
    let dynamic = Dynamic<Int>(0)
    var bond1: Bond<Int>? = Bond<Int>({ v in })
    let bond2: Bond<Int>? = Bond<Int>({ v in })
    
    bond1?.bind(dynamic)
    bond2?.bind(dynamic)

    XCTAssert(dynamic.numberOfBoundBonds == 2, "Initial bonding unsuccessful")
    
    bond1 = nil
    
    // removal is triggered on next change
    dynamic.value = 1
    
    XCTAssert(dynamic.numberOfBoundBonds == 1, "Clearing unsuccessful")
  }
  
  func testBiDirectionalBinding() {
    var d1: Dynamic<Int>! = Dynamic(1)
    var d2: Dynamic<Int>! = Dynamic(2)
    
    var d1ObservedValue: Int = d1.value
    var d2ObservedValue: Int = d2.value
    
    var d1bond: Bond<Int>! = Bond<Int>() { d1ObservedValue = $0 }; d1 ->> d1bond
    var d2bond: Bond<Int>! = Bond<Int>() { d2ObservedValue = $0 }; d2 ->> d2bond
    
    d2 <->> d1
    
    XCTAssert(d1.value == d2.value, "Initial values")
    XCTAssert(d1ObservedValue == d2ObservedValue, "Initial observed values")
    
    d1.value = 3
    XCTAssert(d1.value == d2.value, "Values after changing first dynamic")
    XCTAssert(d1ObservedValue == d2ObservedValue, "Observed values after changing first dynamic")
    
    d2.value = 4
    XCTAssert(d1.value == d2.value, "Values after changing second dynamic")
    XCTAssert(d1ObservedValue == d2ObservedValue, "Observed values after changing second dynamic")
    
    d1bond = nil
    d2bond = nil
    
    weak var d1w = d1
    weak var d2w = d2
    
    d2 = nil
    XCTAssert(d2w != nil, "Second should remain retained by first")
    
    d1 = nil
    XCTAssert(d2w == nil, "Nilling first should delete second")
    XCTAssert(d1w == nil, "Nilling first should delete first, too")
  }
  
  func testOptionals() {
    let dynamic = Dynamic<Int?>(nil)
    var observedValue: Int? = 999
    let bond = Bond<Int?>() { observedValue = $0 }
    
    XCTAssert(observedValue == 999)
    dynamic.bindTo(bond)
    XCTAssert(observedValue == nil)

    XCTAssert(dynamic.valid == true, "Should be valid")
    XCTAssert(dynamic.value == nil, "Should not crash")
    
    dynamic.value = 5
    XCTAssert(observedValue == 5)
    XCTAssert(dynamic.valid == true, "Should be valid")
    
    dynamic.value = nil
    XCTAssert(observedValue == nil)
    XCTAssert(dynamic.valid == true, "Should be valid")
    
    dynamic.value = 2
    XCTAssert(observedValue == 2)
    XCTAssert(dynamic.valid == true, "Should be valid")
    
    let filtered = dynamic.filter { $0 == nil || $0! < 1 }
    XCTAssert(filtered.valid == false, "Should not be valid")
    
    dynamic.value = nil
    XCTAssert(filtered.valid == true, "Should be valid")
    XCTAssert(filtered.value == nil)
    
    dynamic.value = 5
    XCTAssert(filtered.valid == true, "Should be valid")
    XCTAssert(filtered.value == nil)
    
    dynamic.value = -4
    XCTAssert(filtered.valid == true, "Should be valid")
    XCTAssert(filtered.value == -4)
  }
}
