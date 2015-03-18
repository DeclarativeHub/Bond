//
//  UISliderTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UISliderTests: XCTestCase {

  func testUISliderDynamic() {
    var dynamicDriver = Dynamic<Float>(0)
    let slider = UISlider()
    
    slider.value = 0.1
    XCTAssert(slider.value == 0.1, "Initial value")
    
    dynamicDriver <->> slider.dynValue
    XCTAssert(slider.value == 0.0, "Slider value after binding")
    
    dynamicDriver.value = 0.5
    XCTAssert(slider.value == 0.5, "Slider value reflects dynamic value change")
    
    slider.value = 0.8
    slider.sendActionsForControlEvents(.ValueChanged) // simulate user input
    XCTAssert(dynamicDriver.value == 0.8, "Dynamic value reflects slider value change")
  }
}
