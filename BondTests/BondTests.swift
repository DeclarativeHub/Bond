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

  func testEquatable() {
    let bond1 = Bond<Int>({ value in })
    let bond2 = Bond<Int>({ value in })

    XCTAssert(bond1 == bond1 && bond2 == bond2, "Bonds should be equal if they are identical")
    XCTAssert(bond1 != bond2, "Bonds should not be equal if they are not identical")
  }

  func testBoxEquatable() {
    let bond1 = Bond<Int>({ value in })
    let bond2 = Bond<Int>({ value in })

    // Referencing to the same bond.
    let bondBox1 = BondBox(bond1)
    let bondBox2 = BondBox(bond1)

    // Referencing to other bond.
    let bondBox3 = BondBox(bond2)

    XCTAssert(bondBox1 == bondBox2, "BondBoxes should be equal if wrapped Bonds are identical")
    XCTAssert(bondBox1 != bondBox3 && bondBox2 != bondBox3, "BondBoxes should not be equal if wrapped Bonds are not identical")
  }

  func testBoxEquatableIfNilled() {
    var bond: Bond? = Bond<Int>({ value in })

    // Referencing to the same bond.
    let bondBox1 = BondBox(bond!)
    let bondBox2 = BondBox(bond!)

    // Nil out the bond.
    bond = nil

    XCTAssert(bondBox1 == bondBox2, "BondBoxes that used to wrap the same Bond should be marked equal even if the wrapped Bond is lost")
  }

  func testHashable() {
    let bond = Bond<Int>({ value in })
    let ptrHash = unsafeAddressOf(bond).hashValue

    XCTAssert(bond.hashValue == ptrHash, "Each Bond should have draw its hash from memory address")
  }
}
