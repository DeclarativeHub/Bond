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
    let observable = Observable<String>("b")
    let label = UILabel()
        
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
        
    observable.bindTo(label.bnd_text)
    XCTAssert(label.text == "b", "Value after binding")
        
    observable.value = "c"
    XCTAssert(label.text == "c", "Value after observable change")
  }
    
  func testUILabelAttributedTextBond() {
    let observable = Observable<NSAttributedString>(NSAttributedString(string: "b"))
    let label = UILabel()
        
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
        
    observable.bindTo(label.bnd_attributedText)
    XCTAssert(label.attributedText!.string == "b", "Value after binding")
        
    observable.value = NSAttributedString(string: "c")
    XCTAssert(label.attributedText!.string == "c", "Value after observable change")
  }
    
  func testUILabelTextColorBond() {
    let observable = Observable<UIColor>(UIColor.blackColor())
    let label = UILabel()
        
    label.textColor = UIColor.redColor()
    XCTAssert(label.textColor == UIColor.redColor(), "Initial Value")
        
    observable.bindTo(label.bnd_textColor)
    XCTAssert(label.textColor == UIColor.blackColor(), "Value after binding")
        
    observable.value = UIColor.blueColor()
    XCTAssert(label.textColor == UIColor.blueColor(), "Value after observable change")
  }
}
