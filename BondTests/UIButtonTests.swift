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
    var dynamicDriver = Dynamic<Bool>(false)
    let button = UIButton()
    
    button.enabled = true
    XCTAssert(button.enabled == true, "Initial value")
    
    dynamicDriver ->> button.designatedBond
    XCTAssert(button.enabled == false, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssert(button.enabled == true, "Value after dynamic change")
  }
  
  func testUIButtonTitleBond() {
    var dynamicDriver = Dynamic<String>("b")
    let button = UIButton()
    
    button.titleLabel?.text = "a"
    XCTAssert(button.titleLabel?.text == "a", "Initial value")
    
    dynamicDriver ->> button.dynTitle
    XCTAssert(button.titleLabel?.text == "b", "Value after binding")
    
    dynamicDriver.value = "c"
    XCTAssert(button.titleLabel?.text == "c", "Value after dynamic change")
  }
  
  func testUIButtonImageBond() {
    let image1 = UIImage()
    let image2 = UIImage()
    var dynamicDriver = Dynamic<UIImage?>(nil)
    let button = UIButton()
    
    button.setImage(image1, forState: .Normal)
    XCTAssert(button.imageForState(.Normal) == image1, "Initial value")
    
    dynamicDriver ->> button.dynImageForNormalState
    XCTAssert(button.imageForState(.Normal) == nil, "Value after binding")
    
    dynamicDriver.value = image2
    XCTAssert(button.imageForState(.Normal) == image2, "Value after dynamic change")
  }
  
  func testUIButtonDynamic() {
    let button = UIButton()
    
    var observedValue = UIControlEvents.AllEvents
    let bond = Bond<UIControlEvents>() { v in observedValue = v }
    
    XCTAssert(button.dynEvent.faulty == true, "Should be faulty initially")
    
    button.dynEvent.filter(==, .TouchUpInside) ->> bond
    XCTAssert(observedValue == UIControlEvents.AllEvents, "Value after binding should not be changed")
    
    button.sendActionsForControlEvents(.TouchDragInside)
    XCTAssert(observedValue == UIControlEvents.AllEvents, "Dynamic change does not pass test - should not update observedValue")
    
    button.sendActionsForControlEvents(.TouchUpInside)
    XCTAssert(observedValue == UIControlEvents.TouchUpInside, "Dynamic change passes test - should update observedValue")
  }
}
