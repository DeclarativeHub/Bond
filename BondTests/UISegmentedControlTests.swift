//
//  UISegmentedControlTests.swift
//  Bond
//
//  Created by Srđan Rašić on 08/09/15.
//  Copyright © 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UISegmentedControlTests: XCTestCase {
  
  func testSegmentedControlObservable() {
    let observable = Observable<Int>(0)
    let segmentedControl = UISegmentedControl(items: ["A", "B", "C"])
    
    XCTAssert(segmentedControl.selectedSegmentIndex == UISegmentedControlNoSegment, "Initial value")
    
    observable.bidirectionalBindTo(segmentedControl.bnd_selectedSegmentIndex)
    XCTAssert(segmentedControl.selectedSegmentIndex == 0, "Value after binding")
    
    observable.value = 1
    XCTAssert(segmentedControl.selectedSegmentIndex == 1, "Index reflects observable value change")
    
    segmentedControl.selectedSegmentIndex = 2
    segmentedControl.sendActionsForControlEvents(.ValueChanged) // simulate user input
    XCTAssert(observable.value == 2, "Observable value reflects segmented control value change")
  }
}
