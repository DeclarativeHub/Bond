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
    let scalar = Scalar<Bool>(false)
    let view = UIView()
    
    view.hidden = true
    XCTAssert(view.hidden == true, "Initial value")
    
    scalar |> view.bnd_hidden
    XCTAssert(view.hidden == false, "Value after binding")
    
    scalar.value = true
    XCTAssert(view.hidden == true, "Value after scalar change")
  }
  
  func testUIViewAlphaBond() {
    let scalar = Scalar<CGFloat>(0.1)
    let view = UIView()
    
    view.alpha = 0.0
    XCTAssert(abs(view.alpha - 0.0) < 0.0001, "Initial value")
    
    scalar |> view.bnd_alpha
    XCTAssert(abs(view.alpha - 0.1) < 0.0001, "Value after binding")
    
    scalar.value = 0.5
    XCTAssert(abs(view.alpha - 0.5) < 0.0001, "Value after scalar change")
  }
  
  func testUIViewBackgroundColorBond() {
    let scalar = Scalar<UIColor>(UIColor.blackColor())
    let view = UIView()
    
    view.backgroundColor = UIColor.redColor()
    XCTAssert(view.backgroundColor == UIColor.redColor(), "Initial value")
    
    scalar |> view.bnd_backgroundColor
    XCTAssert(view.backgroundColor == UIColor.blackColor(), "Value after binding")
    
    scalar.value = UIColor.blueColor()
    XCTAssert(view.backgroundColor == UIColor.blueColor(), "Value after scalar change")
  }
    
  func testUIViewUserInteractionEnabledBond() {
    let scalar = Scalar<Bool>(false)
    let view = UIView()

    view.userInteractionEnabled = true
    XCTAssert(view.userInteractionEnabled == true, "Initial value")

    scalar |> view.bnd_userInteractionEnabled
    XCTAssert(view.userInteractionEnabled == false, "Value After Binding")

    scalar.value = true
    XCTAssert(view.userInteractionEnabled == true, "Value after scalar change")
  }
}
