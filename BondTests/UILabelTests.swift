//
//  UILabelTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UILabelTests: XCTestCase {

  func testUILabelBond() {
    var dynamicDriver = Dynamic<String>("b")
    let label = UILabel()
    
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
    
    dynamicDriver ->> label.designatedBond
    XCTAssert(label.text == "b", "Value after binding")
    
    dynamicDriver.value = "c"
    XCTAssert(label.text == "c", "Value after dynamic change")
  }
  
  func testUILabelAttributedTextBond() {
    var dynamicDriver = Dynamic<NSAttributedString>(NSAttributedString(string: "b"))
    let label = UILabel()
    
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
    
    dynamicDriver ->> label.dynAttributedText
    XCTAssert(label.attributedText.string == "b", "Value after binding")
    
    dynamicDriver.value = NSAttributedString(string: "c")
    XCTAssert(label.attributedText.string == "c", "Value after dynamic change")
  }
}
