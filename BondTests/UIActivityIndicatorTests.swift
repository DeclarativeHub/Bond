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
    var dynamicDriver = Dynamic<Bool>(false)
    let view = UIActivityIndicatorView()
    
    view.startAnimating()
    XCTAssert(view.isAnimating() == true, "Initial value")
    
    dynamicDriver ->> view.dynIsAnimating
    XCTAssert(view.isAnimating() == false, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssert(view.isAnimating() == true, "Value after dynamic change")
  }
}
