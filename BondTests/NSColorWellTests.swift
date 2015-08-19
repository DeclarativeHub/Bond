//
//  NSColorWellTests.swift
//  Bond
//
//  Created by Tony Arnold on 16/04/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import Cocoa
import XCTest

class NSColorWellTests: XCTestCase {
  
  func testNSColorWellColorBond() {
    let dynamicDriver = Observable<NSColor>(NSColor.cyanColor())
    let colorWell = NSColorWell(frame: NSZeroRect)
    
    colorWell.color = NSColor.redColor()
    XCTAssertEqual(colorWell.color, NSColor.redColor(), "Initial value")
    
    dynamicDriver.bindTo(colorWell.bnd_color)
    XCTAssertEqual(colorWell.color, NSColor.cyanColor(), "Value after binding")
    
    dynamicDriver.value = NSColor.yellowColor()
    XCTAssertEqual(colorWell.color, NSColor.yellowColor(), "Value after dynamic change")
  }
}
