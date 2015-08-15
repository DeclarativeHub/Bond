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
    let scalar = Scalar<String>("b")
    let label = UILabel()
        
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
        
    scalar.bindTo(label.bnd_text)
    XCTAssert(label.text == "b", "Value after binding")
        
    scalar.value = "c"
    XCTAssert(label.text == "c", "Value after scalar change")
  }
    
  func testUILabelAttributedTextBond() {
    let scalar = Scalar<NSAttributedString>(NSAttributedString(string: "b"))
    let label = UILabel()
        
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
        
    scalar.bindTo(label.bnd_attributedText)
    XCTAssert(label.attributedText!.string == "b", "Value after binding")
        
    scalar.value = NSAttributedString(string: "c")
    XCTAssert(label.attributedText!.string == "c", "Value after scalar change")
  }
    
  func testUILabelTextColorBond() {
    let scalar = Scalar<UIColor>(UIColor.blackColor())
    let label = UILabel()
        
    label.textColor = UIColor.redColor()
    XCTAssert(label.textColor == UIColor.redColor(), "Initial Value")
        
    scalar.bindTo(label.bnd_textColor)
    XCTAssert(label.textColor == UIColor.blackColor(), "Value after binding")
        
    scalar.value = UIColor.blueColor()
    XCTAssert(label.textColor == UIColor.blueColor(), "Value after scalar change")
  }
}
