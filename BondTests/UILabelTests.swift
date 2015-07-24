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
    let dynamicDriver = Dynamic<String>("b")
    let label = UILabel()
        
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
        
    dynamicDriver ->> label.designatedBond
    XCTAssert(label.text == "b", "Value after binding")
        
    dynamicDriver.value = "c"
    XCTAssert(label.text == "c", "Value after dynamic change")
  }
    
  func testUILabelAttributedTextBond() {
    let dynamicDriver = Dynamic<NSAttributedString>(NSAttributedString(string: "b"))
    let label = UILabel()
        
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
        
    dynamicDriver ->> label.dynAttributedText
    XCTAssert(label.attributedText!.string == "b", "Value after binding")
    
    dynamicDriver.value = NSAttributedString(string: "c")
    XCTAssert(label.attributedText!.string == "c", "Value after dynamic change")
  }
    
  func testUILabelTextColorBond() {
    let dynamicDriver = Dynamic<UIColor>(UIColor.blackColor())
    let label = UILabel()
        
    label.textColor = UIColor.redColor()
    XCTAssert(label.textColor == UIColor.redColor(), "Initial Value")
        
    dynamicDriver ->> label.dynTextColor
    XCTAssert(label.textColor == UIColor.blackColor(), "Value after binding")
        
    dynamicDriver.value = UIColor.blueColor()
    XCTAssert(label.textColor == UIColor.blueColor(), "Value after dynamic change")
  }
}
