//
//  UISegmentedControlTests.swift
//  Bond
//
//  Created by Austin Cooley on 6/23/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UISegmentedControlTests: XCTestCase {
  
  func testUISegmentedControlDynamic() {
    let segmentedControl = UISegmentedControl()
    
    var observedValue = UIControlEvents.AllEvents
    let bond = Bond<UIControlEvents>() { v in observedValue = v }
    
    XCTAssert(segmentedControl.dynEvent.valid == false, "Should be faulty initially")
    
    segmentedControl.dynEvent.filter(==, .ValueChanged) ->> bond
    XCTAssert(observedValue == UIControlEvents.AllEvents, "Value after binding should not be changed")
    
    segmentedControl.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
    XCTAssert(observedValue == UIControlEvents.AllEvents, "Dynamic change does not pass test - should not update observedValue")
    
    segmentedControl.sendActionsForControlEvents(.ValueChanged)
    XCTAssert(observedValue == UIControlEvents.ValueChanged, "Dynamic change passes test - should update observedValue")
  }
}

