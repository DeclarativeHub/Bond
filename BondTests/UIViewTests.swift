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
    let observable = Observable<Bool>(false)
    let view = UIView()
    
    view.hidden = true
    XCTAssert(view.hidden == true, "Initial value")
    
    observable.bindTo(view.bnd_hidden)
    XCTAssert(view.hidden == false, "Value after binding")
    
    observable.value = true
    XCTAssert(view.hidden == true, "Value after observable change")
  }
  
  func testUIViewAlphaBond() {
    let observable = Observable<CGFloat>(0.1)
    let view = UIView()
    
    view.alpha = 0.0
    XCTAssert(abs(view.alpha - 0.0) < 0.0001, "Initial value")
    
    observable.bindTo(view.bnd_alpha)
    XCTAssert(abs(view.alpha - 0.1) < 0.0001, "Value after binding")
    
    observable.value = 0.5
    XCTAssert(abs(view.alpha - 0.5) < 0.0001, "Value after observable change")
  }
  
  func testUIViewBackgroundColorBond() {
    let observable = Observable<UIColor>(UIColor.blackColor())
    let view = UIView()
    
    view.backgroundColor = UIColor.redColor()
    XCTAssert(view.backgroundColor == UIColor.redColor(), "Initial value")
    
    observable.bindTo(view.bnd_backgroundColor)
    XCTAssert(view.backgroundColor == UIColor.blackColor(), "Value after binding")
    
    observable.value = UIColor.blueColor()
    XCTAssert(view.backgroundColor == UIColor.blueColor(), "Value after observable change")
  }
    
  func testUIViewUserInteractionEnabledBond() {
    let observable = Observable<Bool>(false)
    let view = UIView()

    view.userInteractionEnabled = true
    XCTAssert(view.userInteractionEnabled == true, "Initial value")

    observable.bindTo(view.bnd_userInteractionEnabled)
    XCTAssert(view.userInteractionEnabled == false, "Value After Binding")

    observable.value = true
    XCTAssert(view.userInteractionEnabled == true, "Value after observable change")
  }

  func testUIViewTintColorBond() {
    let observable = Observable<UIColor>(UIColor.blackColor())
    let view = UIView()

    view.tintColor = UIColor.redColor()
    XCTAssert(view.tintColor == UIColor.redColor(), "Initial value")

    observable.bindTo(view.bnd_tintColor)
    XCTAssert(view.tintColor == UIColor.blackColor(), "Value after binding")

    observable.value = UIColor.blueColor()
    XCTAssert(view.tintColor == UIColor.blueColor(), "Value after observable change")
  }

}
