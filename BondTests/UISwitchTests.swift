//
//  UISwitchTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UISwitchTests: XCTestCase {

  func testUISwitchObservable() {
    let observable = Observable<Bool>(false)
    let uiSwitch = UISwitch()
    
    uiSwitch.on = true
    XCTAssert(uiSwitch.on == true, "Initial value")
    
    observable.bidirectionalBindTo(uiSwitch.bnd_on)
    XCTAssert(uiSwitch.on == false, "Switch value after binding")
    
    observable.value = true
    XCTAssert(uiSwitch.on == true, "Switch value reflects observable value change")
    
    uiSwitch.on = false
    uiSwitch.sendActionsForControlEvents(.ValueChanged) //simulate user input
    XCTAssert(observable.value == false, "Observable value reflects switch value change")
  }
  
  func testOneWayOperators() {
    var bondedValue = true
    let observable = Observable<Bool>(false)
    let switch1 = UISwitch()
    let switch2 = UISwitch()
    
    XCTAssertEqual(bondedValue, true, "Initial value")
    
    observable.bindTo(switch1.bnd_on)
    switch1.bnd_on.bindTo(switch2.bnd_on)
    switch2.bnd_on.observe {
      bondedValue = $0
    }
    
    XCTAssertEqual(bondedValue, false, "Value after binding")

    observable.value = true
    XCTAssertEqual(bondedValue, true, "Value after change")
  }
  
  func testTwoWayOperators() {
    let observable1 = Observable<Bool>(true)
    let observable2 = Observable<Bool>(false)
    let switch1 = UISwitch()
    let switch2 = UISwitch()
    
    XCTAssertEqual(observable1.value, true, "Initial value")
    XCTAssertEqual(observable2.value, false, "Initial value")
    
    observable1.bidirectionalBindTo(switch1.bnd_on)
    switch1.bnd_on.bidirectionalBindTo(switch2.bnd_on)
    switch2.bnd_on.bidirectionalBindTo(observable2)
    
    XCTAssertEqual(observable1.value, true, "Value after binding")
    XCTAssertEqual(observable2.value, true, "Value after binding")
    
    observable1.value = false
    
    XCTAssertEqual(observable1.value, false, "Value after change")
    XCTAssertEqual(observable2.value, false, "Value after change")

    observable2.value = true
    
    XCTAssertEqual(observable1.value, true, "Value after change")
    XCTAssertEqual(observable2.value, true, "Value after change")
  }
}
