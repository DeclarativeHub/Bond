//
//  NSButtonTests.swift
//  Bond
//
//  Created by Tony Arnold on 16/04/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import Cocoa
import XCTest

class NSButtonTests: XCTestCase {
  
  func testNSButtonStateBond() {
    let dynamicDriver = Observable<Int>(NSOffState)
    let button = NSButton(frame: NSZeroRect)
    
    button.state = NSOnState
    XCTAssertEqual(button.state, NSOnState, "Initial value")
    
    dynamicDriver.bindTo(button.bnd_state)
    XCTAssertEqual(button.state, NSOffState, "Value after binding")
    
    dynamicDriver.value = NSOnState
    XCTAssertEqual(button.state, NSOnState, "Value after dynamic change")
  }
  
}
