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
}
