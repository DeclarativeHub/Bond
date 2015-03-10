//
//  UIViewTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UIViewTests: XCTestCase {

  func testUIViewHiddenBond() {
    var dynamicDriver = Dynamic<Bool>(false)
    let view = UIView()
    
    view.hidden = true
    XCTAssert(view.hidden == true, "Initial value")
    
    dynamicDriver ->> view.dynHidden
    XCTAssert(view.hidden == false, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssert(view.hidden == true, "Value after dynamic change")
  }
  
  func testUIViewAlphaBond() {
    var dynamicDriver = Dynamic<CGFloat>(0.1)
    let view = UIView()
    
    view.alpha = 0.0
    XCTAssert(abs(view.alpha - 0.0) < 0.0001, "Initial value")
    
    dynamicDriver ->> view.dynAlpha
    XCTAssert(abs(view.alpha - 0.1) < 0.0001, "Value after binding")
    
    dynamicDriver.value = 0.5
    XCTAssert(abs(view.alpha - 0.5) < 0.0001, "Value after dynamic change")
  }
  
  func testUIViewBackgroundColorBond() {
    var dynamicDriver = Dynamic<UIColor>(UIColor.blackColor())
    let view = UIView()
    
    view.backgroundColor = UIColor.redColor()
    XCTAssert(view.backgroundColor == UIColor.redColor(), "Initial value")
    
    dynamicDriver ->> view.dynBackgroundColor
    XCTAssert(view.backgroundColor == UIColor.blackColor(), "Value after binding")
    
    dynamicDriver.value = UIColor.blueColor()
    XCTAssert(view.backgroundColor == UIColor.blueColor(), "Value after dynamic change")
  }
}
