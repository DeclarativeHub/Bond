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
    let scalar = Scalar<Bool>(false)
    let view = UIActivityIndicatorView()
    
    view.startAnimating()
    XCTAssert(view.isAnimating() == true, "Initial value")
    
    scalar |> view.bnd_animating
    XCTAssert(view.isAnimating() == false, "Value after binding")
    
    scalar.value = true
    XCTAssert(view.isAnimating() == true, "Value after scalar change")
  }
}
