//
//  UIButtonTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UIButtonTests: XCTestCase {

  func testUIButtonEnabledBond() {
    let scalar = Scalar<Bool>(false)
    let button = UIButton()
    
    button.enabled = true
    XCTAssert(button.enabled == true, "Initial value")
    
    scalar |> button.bnd_enabled
    XCTAssert(button.enabled == false, "Value after binding")
    
    scalar.value = true
    XCTAssert(button.enabled == true, "Value after scalar change")
  }
  
  func testUIButtonTitleBond() {
    let scalar = Scalar<String>("b")
    let button = UIButton()
    
    button.titleLabel?.text = "a"
    XCTAssert(button.titleLabel?.text == "a", "Initial value")
    
    scalar |> button.bnd_title
    XCTAssert(button.titleLabel?.text == "b", "Value after binding")
    
    scalar.value = "c"
    XCTAssert(button.titleLabel?.text == "c", "Value after scalar change")
  }
  
  func testUIButtonScalar() {
    let button = UIButton()
    
    var observedValue = UIControlEvents.AllEvents
    
    button.bnd_tap.observe {
      observedValue = .TouchUpInside
    }
    
    XCTAssert(observedValue == UIControlEvents.AllEvents, "Value after binding should not be changed")
    
    button.sendActionsForControlEvents(.TouchDragInside)
    XCTAssert(observedValue == UIControlEvents.AllEvents, "Scalar change does not pass test - should not update observedValue")
    
    button.sendActionsForControlEvents(.TouchUpInside)
    XCTAssert(observedValue == UIControlEvents.TouchUpInside, "Scalar change passes test - should update observedValue")
  }
}
