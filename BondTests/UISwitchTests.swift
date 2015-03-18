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

  func testUISwitchDynamic() {
    var dynamicDriver = Dynamic<Bool>(false)
    let uiSwitch = UISwitch()
    
    uiSwitch.on = true
    XCTAssert(uiSwitch.on == true, "Initial value")
    
    dynamicDriver <->> uiSwitch.dynOn
    XCTAssert(uiSwitch.on == false, "Switch value after binding")
    
    dynamicDriver.value = true
    XCTAssert(uiSwitch.on == true, "Switch value reflects dynamic value change")
    
    uiSwitch.on = false
    uiSwitch.sendActionsForControlEvents(.ValueChanged) //simulate user input
    XCTAssert(dynamicDriver.value == false, "Dynamic value reflects switch value change")
  }
  
  func testOneWayOperators() {
    var bondedValue = true
    let bond = Bond { bondedValue = $0 }
    let dynamicDriver = Dynamic<Bool>(false)
    let switch1 = UISwitch()
    let switch2 = UISwitch()
    
    XCTAssertEqual(bondedValue, true, "Initial value")
    
    dynamicDriver ->> switch1
    switch1 ->> switch2
    switch2 ->> bond
    
    XCTAssertEqual(bondedValue, false, "Value after binding")
    
    dynamicDriver.value = true
    
    XCTAssertEqual(bondedValue, true, "Value after change")
  }
  
  func testTwoWayOperators() {
    let dynamicDriver1 = Dynamic<Bool>(true)
    let dynamicDriver2 = Dynamic<Bool>(false)
    let switch1 = UISwitch()
    let switch2 = UISwitch()
    
    XCTAssertEqual(dynamicDriver1.value, true, "Initial value")
    XCTAssertEqual(dynamicDriver2.value, false, "Initial value")
    
    dynamicDriver1 <->> switch1
    switch1 <->> switch2
    switch2 <->> dynamicDriver2
    
    XCTAssertEqual(dynamicDriver1.value, true, "Value after binding")
    XCTAssertEqual(dynamicDriver2.value, true, "Value after binding")
    
    dynamicDriver1.value = false
    
    XCTAssertEqual(dynamicDriver1.value, false, "Value after change")
    XCTAssertEqual(dynamicDriver2.value, false, "Value after change")

    dynamicDriver2.value = true
    
    XCTAssertEqual(dynamicDriver1.value, true, "Value after change")
    XCTAssertEqual(dynamicDriver2.value, true, "Value after change")
  }
}
