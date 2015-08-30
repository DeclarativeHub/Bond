//
//  UIActivityIndicatorTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UIActivityIndicatorTests: XCTestCase {

  func testUIActivityIndicatorViewHiddenBond() {
    let observable = Observable<Bool>(false)
    let view = UIActivityIndicatorView()
    
    view.startAnimating()
    XCTAssert(view.isAnimating() == true, "Initial value")
    
    observable.bindTo(view.bnd_animating)
    XCTAssert(view.isAnimating() == false, "Value after binding")
    
    observable.value = true
    XCTAssert(view.isAnimating() == true, "Value after observable change")
  }
}
