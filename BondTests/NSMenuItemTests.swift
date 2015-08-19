//
//  NSMenuItemTests.swift
//  Bond
//
//  Created by Tony Arnold on 16/04/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import Cocoa
import XCTest

class NSMenuItemTests: XCTestCase {
  
  func testNSMenuItemEnabledBond() {
    let dynamicDriver = Observable<Bool>(false)
    let menuItem = NSMenuItem()
    
    menuItem.enabled = true
    XCTAssertTrue(menuItem.enabled, "Initial value")
    
    dynamicDriver.bindTo(menuItem.bnd_enabled)
    XCTAssertFalse(menuItem.enabled, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssertTrue(menuItem.enabled, "Value after dynamic change")
  }
  
  func testNSMenuItemStateBond() {
    let dynamicDriver = Observable<Int>(NSOffState)
    let menuItem = NSMenuItem()
    
    menuItem.state = NSOnState
    XCTAssertEqual(menuItem.state, NSOnState, "Initial value")
    
    dynamicDriver.bindTo(menuItem.bnd_state)
    XCTAssertEqual(menuItem.state, NSOffState, "Value after binding")
    
    dynamicDriver.value = NSOnState
    XCTAssertEqual(menuItem.state, NSOnState, "Value after dynamic change")
  }
}
