//
//  CALayerTests.swift
//  Bond
//
//  Created by Tony Arnold on 16/04/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import QuartzCore
import XCTest

#if os(iOS)
  import UIKit
  typealias Color = UIColor
  #else
  import AppKit
  typealias Color = NSColor
#endif

class CALayerTests: XCTestCase {
  
  func testCALayerBackgroundColorBond() {
    let driver = Observable<CGColor>(Color.whiteColor().CGColor)
    let layer = CALayer()

    layer.backgroundColor = Color.redColor().CGColor
    XCTAssert(CGColorEqualToColor(layer.backgroundColor, Color.redColor().CGColor), "Initial value")
    
    driver.bindTo(layer.bnd_backgroundColor)
    XCTAssert(CGColorEqualToColor(layer.backgroundColor, Color.whiteColor().CGColor), "Value after binding")
    
    driver.value = Color.greenColor().CGColor
    XCTAssert(CGColorEqualToColor(layer.backgroundColor, Color.greenColor().CGColor), "Value after dynamic change")
  }
  
}
