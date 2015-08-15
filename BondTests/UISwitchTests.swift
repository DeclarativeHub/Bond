//
//  UISwitchTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UISwitchTests: XCTestCase {

  func testUISwitchScalar() {
    let scalar = Scalar<Bool>(false)
    let uiSwitch = UISwitch()
    
    uiSwitch.on = true
    XCTAssert(uiSwitch.on == true, "Initial value")
    
    scalar.bidirectionalBindTo(uiSwitch.bnd_on)
    XCTAssert(uiSwitch.on == false, "Switch value after binding")
    
    scalar.value = true
    XCTAssert(uiSwitch.on == true, "Switch value reflects scalar value change")
    
    uiSwitch.on = false
    uiSwitch.sendActionsForControlEvents(.ValueChanged) //simulate user input
    XCTAssert(scalar.value == false, "Scalar value reflects switch value change")
  }
  
  func testOneWayOperators() {
    var bondedValue = true
    let scalar = Scalar<Bool>(false)
    let switch1 = UISwitch()
    let switch2 = UISwitch()
    
    XCTAssertEqual(bondedValue, true, "Initial value")
    
    scalar.bindTo(switch1.bnd_on)
    switch1.bnd_on.bindTo(switch2.bnd_on)
    switch2.bnd_on.observe {
      bondedValue = $0
    }
    
    XCTAssertEqual(bondedValue, false, "Value after binding")

    scalar.value = true
    XCTAssertEqual(bondedValue, true, "Value after change")
  }
  
  func testTwoWayOperators() {
    let scalar1 = Scalar<Bool>(true)
    let scalar2 = Scalar<Bool>(false)
    let switch1 = UISwitch()
    let switch2 = UISwitch()
    
    XCTAssertEqual(scalar1.value, true, "Initial value")
    XCTAssertEqual(scalar2.value, false, "Initial value")
    
    scalar1.bidirectionalBindTo(switch1.bnd_on)
    switch1.bnd_on.bidirectionalBindTo(switch2.bnd_on)
    switch2.bnd_on.bidirectionalBindTo(scalar2)
    
    XCTAssertEqual(scalar1.value, true, "Value after binding")
    XCTAssertEqual(scalar2.value, true, "Value after binding")
    
    scalar1.value = false
    
    XCTAssertEqual(scalar1.value, false, "Value after change")
    XCTAssertEqual(scalar2.value, false, "Value after change")

    scalar2.value = true
    
    XCTAssertEqual(scalar1.value, true, "Value after change")
    XCTAssertEqual(scalar2.value, true, "Value after change")
  }
}
