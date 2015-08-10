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

  func testUISliderScalar() {
    let scalar = Scalar<Float>(0)
    let slider = UISlider()
    
    slider.value = 0.1
    XCTAssert(slider.value == 0.1, "Initial value")
    
    scalar |>< slider.bnd_value
    XCTAssert(slider.value == 0.0, "Slider value after binding")
    
    scalar.value = 0.5
    XCTAssert(slider.value == 0.5, "Slider value reflects scalar value change")
    
    slider.value = 0.8
    slider.sendActionsForControlEvents(.ValueChanged) // simulate user input
    XCTAssert(scalar.value == 0.8, "Scalar value reflects slider value change")
  }
  
  func testOneWayOperators() {
    var bondedValue: Float = 0
    let scalar = Scalar<Float>(0.1)
    let slider1 = UISlider()
    let slider2 = UISlider()
    
    XCTAssertEqual(bondedValue, Float(0), "Initial value")
    
    scalar |> slider1.bnd_value
    slider1.bnd_value |> slider2.bnd_value
    slider2.bnd_value.observe {
      bondedValue = $0
    }
    
    XCTAssertEqual(bondedValue, Float(0.1), "Value after binding")
    
    scalar.value = 0.7
    
    XCTAssertEqual(bondedValue, Float(0.7), "Value after change")
  }

  func testTwoWayOperators() {
    let scalar1 = Scalar<Float>(0.1)
    let scalar2 = Scalar<Float>(0.2)
    let slider1 = UISlider()
    let slider2 = UISlider()
    
    XCTAssertEqual(scalar1.value, Float(0.1), "Initial value")
    XCTAssertEqual(scalar2.value, Float(0.2), "Initial value")
    
    scalar1 |>< slider1.bnd_value
    slider1.bnd_value |>< slider2.bnd_value
    slider2.bnd_value |>< scalar2
    
    XCTAssertEqual(scalar1.value, Float(0.1), "Value after binding")
    XCTAssertEqual(scalar2.value, Float(0.1), "Value after binding")
    
    scalar1.value = 0.3
    
    XCTAssertEqual(scalar1.value, Float(0.3), "Value after change")
    XCTAssertEqual(scalar2.value, Float(0.3), "Value after change")

    scalar2.value = 0.4
    
    XCTAssertEqual(scalar1.value, Float(0.4), "Value after change")
    XCTAssertEqual(scalar2.value, Float(0.4), "Value after change")
  }
}
