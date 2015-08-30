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

  func testUISliderObservable() {
    let observable = Observable<Float>(0)
    let slider = UISlider()
    
    slider.value = 0.1
    XCTAssert(slider.value == 0.1, "Initial value")
    
    observable.bidirectionalBindTo(slider.bnd_value)
    XCTAssert(slider.value == 0.0, "Slider value after binding")
    
    observable.value = 0.5
    XCTAssert(slider.value == 0.5, "Slider value reflects observable value change")
    
    slider.value = 0.8
    slider.sendActionsForControlEvents(.ValueChanged) // simulate user input
    XCTAssert(observable.value == 0.8, "Observable value reflects slider value change")
  }
  
  func testOneWayOperators() {
    var bondedValue: Float = 0
    let observable = Observable<Float>(0.1)
    let slider1 = UISlider()
    let slider2 = UISlider()
    
    XCTAssertEqual(bondedValue, Float(0), "Initial value")
    
    observable.bindTo(slider1.bnd_value)
    slider1.bnd_value.bindTo(slider2.bnd_value)
    slider2.bnd_value.observe {
      bondedValue = $0
    }
    
    XCTAssertEqual(bondedValue, Float(0.1), "Value after binding")
    
    observable.value = 0.7
    
    XCTAssertEqual(bondedValue, Float(0.7), "Value after change")
  }

  func testTwoWayOperators() {
    let observable1 = Observable<Float>(0.1)
    let observable2 = Observable<Float>(0.2)
    let slider1 = UISlider()
    let slider2 = UISlider()
    
    XCTAssertEqual(observable1.value, Float(0.1), "Initial value")
    XCTAssertEqual(observable2.value, Float(0.2), "Initial value")
    
    observable1.bidirectionalBindTo(slider1.bnd_value)
    slider1.bnd_value.bidirectionalBindTo(slider2.bnd_value)
    slider2.bnd_value.bidirectionalBindTo(observable2)
    
    XCTAssertEqual(observable1.value, Float(0.1), "Value after binding")
    XCTAssertEqual(observable2.value, Float(0.1), "Value after binding")
    
    observable1.value = 0.3
    
    XCTAssertEqual(observable1.value, Float(0.3), "Value after change")
    XCTAssertEqual(observable2.value, Float(0.3), "Value after change")

    observable2.value = 0.4
    
    XCTAssertEqual(observable1.value, Float(0.4), "Value after change")
    XCTAssertEqual(observable2.value, Float(0.4), "Value after change")
  }
}
