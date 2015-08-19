//
//  NSControlTests.swift
//  Bond
//
//  Created by Tony Arnold on 16/04/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import Cocoa
import XCTest

class NSControlTests: XCTestCase {
  
  func testNSControlEnabledBond() {
    let dynamicDriver = Observable<Bool>(false)
    let control = NSControl(frame: NSZeroRect)
    
    control.enabled = true
    XCTAssertTrue(control.enabled, "Initial value")
    
    dynamicDriver.bindTo(control.bnd_enabled)
    XCTAssertFalse(control.enabled, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssertTrue(control.enabled, "Value after dynamic change")
  }
}
