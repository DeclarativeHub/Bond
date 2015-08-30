//
//  NSImageViewTests.swift
//  Bond
//
//  Created by Tony Arnold on 16/04/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import Cocoa
import XCTest

class NSImageViewTests: XCTestCase {
  
  func testNSImageViewImageBond() {
    let image = NSImage()
    let dynamicDriver = Observable<NSImage?>(nil)
    let control = NSImageView(frame: NSZeroRect)
    
    control.image = image
    XCTAssertEqual(control.image!, image, "Initial value")
    
    dynamicDriver.bindTo(control.bnd_image)
    XCTAssertNil(control.image, "Value after binding")
    
    dynamicDriver.value = image
    XCTAssertEqual(control.image!, image, "Value after dynamic change")
  }
}
