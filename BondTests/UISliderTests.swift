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
  
  func testOneWayOperators() {
    var bondedValue: Float = 0
    let bond = Bond { bondedValue = $0 }
    let dynamicDriver = Dynamic<Float>(0.1)
    let slider1 = UISlider()
    let slider2 = UISlider()
    
    XCTAssertEqual(bondedValue, Float(0), "Initial value")
    
    dynamicDriver ->> slider1
    slider1 ->> slider2
    slider2 ->> bond
    
    XCTAssertEqual(bondedValue, Float(0.1), "Value after binding")
    
    dynamicDriver.value = 0.7
    
    XCTAssertEqual(bondedValue, Float(0.7), "Value after change")
  }

  func testTwoWayOperators() {
    let dynamicDriver1 = Dynamic<Float>(0.1)
    let dynamicDriver2 = Dynamic<Float>(0.2)
    let slider1 = UISlider()
    let slider2 = UISlider()
    
    XCTAssertEqual(dynamicDriver1.value, Float(0.1), "Initial value")
    XCTAssertEqual(dynamicDriver2.value, Float(0.2), "Initial value")
    
    dynamicDriver1 <->> slider1
    slider1 <->> slider2
    slider2 <->> dynamicDriver2
    
    XCTAssertEqual(dynamicDriver1.value, Float(0.1), "Value after binding")
    XCTAssertEqual(dynamicDriver2.value, Float(0.1), "Value after binding")
    
    dynamicDriver1.value = 0.3
    
    XCTAssertEqual(dynamicDriver1.value, Float(0.3), "Value after change")
    XCTAssertEqual(dynamicDriver2.value, Float(0.3), "Value after change")

    dynamicDriver2.value = 0.4
    
    XCTAssertEqual(dynamicDriver1.value, Float(0.4), "Value after change")
    XCTAssertEqual(dynamicDriver2.value, Float(0.4), "Value after change")
  }
}
