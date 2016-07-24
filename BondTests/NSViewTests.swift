//
//  NSViewTests.swift
//  Bond
//
//  Created by mshibanami on 24/7/2016.
//  Copyright (c) 2016 Bond. All rights reserved.
//

import Bond
import Cocoa
import XCTest

class NSViewTests: XCTestCase {
  
  func testNSViewAlphaValueBond() {
    let observable = Observable<CGFloat>(0.1)
    let view = NSView()
    
    view.alphaValue = 0.0
    XCTAssert(abs(view.alphaValue - 0.0) < 0.0001, "Initial value")
    
    observable.bindTo(view.bnd_alphaValue)
    XCTAssert(abs(view.alphaValue - 0.1) < 0.0001, "Value after binding")
    
    observable.value = 0.5
    XCTAssert(abs(view.alphaValue - 0.5) < 0.0001, "Value after observable change")
  }
  
  func testNSViewHiddenBond() {
    let observable = Observable<Bool>(false)
    let view = NSView()
    
    view.hidden = true
    XCTAssert(view.hidden == true, "Initial value")
    
    observable.bindTo(view.bnd_hidden)
    XCTAssert(view.hidden == false, "Value after binding")
    
    observable.value = true
    XCTAssert(view.hidden == true, "Value after observable change")
  }
}
