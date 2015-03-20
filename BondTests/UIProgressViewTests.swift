//
//  UIProgressViewTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UIProgressViewTests: XCTestCase {

  func testUIProgressViewBond() {
    var dynamicDriver = Dynamic<Float>(0)
    let progressView = UIProgressView()
    
    progressView.progress = 0.1
    XCTAssert(progressView.progress == 0.1, "Initial value")
    
    dynamicDriver ->> progressView.designatedBond
    XCTAssert(progressView.progress == 0.0, "Value after binding")
    
    dynamicDriver.value = 0.5
    XCTAssert(progressView.progress == 0.5, "Value after dynamic change")
  }
}
