//
//  UITextViewTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UITextViewTests: XCTestCase {

  func testUITextViewDynamic() {
    var dynamicDriver = Dynamic<String>("b")
    let textView = UITextView()
    
    textView.text = "a"
    XCTAssert(textView.text == "a", "Initial value")
    
    dynamicDriver <->> textView.dynText
    XCTAssert(textView.text == "b", "Text view value after binding")
    
    dynamicDriver.value = "c"
    XCTAssert(textView.text == "c", "Text view value reflects dynamic value change")
    
    textView.text = "d"
    NSNotificationCenter.defaultCenter().postNotificationName(UITextViewTextDidChangeNotification, object: textView)
    XCTAssert(textView.dynText.value == "d", "Dynamic value reflects text view value change")
    XCTAssert(dynamicDriver.value == "d", "Dynamic value reflects text view value change")
  }
  
  func testUITextViewAttributedDynamic() {
    var dynamicDriver = Dynamic<NSAttributedString>(NSAttributedString(string: "b"))
    let textView = UITextView()
    
    textView.attributedText = NSAttributedString(string: "a")
    XCTAssert(textView.attributedText.string == "a", "Initial value")
    
    dynamicDriver <->> textView.dynAttributedText
    XCTAssert(textView.attributedText.string == "b", "Text view value after binding")
    
    dynamicDriver.value = NSAttributedString(string: "c")
    XCTAssert(textView.attributedText.string == "c", "Text view value reflects dynamic value change")
    
    textView.attributedText = NSAttributedString(string: "d")
    NSNotificationCenter.defaultCenter().postNotificationName(UITextViewTextDidChangeNotification, object: textView)
    XCTAssert(textView.dynAttributedText.value.string == "d", "Dynamic value reflects text view value change")
    XCTAssert(dynamicDriver.value.string == "d", "Dynamic value reflects text view value change")
  }
  
  func testOneWayOperators() {
    var bondedValue: String = ""
    let bond = Bond { bondedValue = $0 }
    let dynamicDriver = Dynamic<String>("a")
    let textView1 = UITextView()
    let textView2 = UITextView()
    let textField = UITextField()
    let label = UILabel()
    
    XCTAssertEqual(bondedValue, "", "Initial value")
    XCTAssertEqual(textField.text, "", "Initial value")
    XCTAssertEqual(label.text, nil, "Initial value")
    
    dynamicDriver ->> textView1
    textView1 ->> textView2
    textView2 ->> bond
    textView2 ->> textField
    textView2 ->> label
    
    XCTAssertEqual(bondedValue, "a", "Value after binding")
    XCTAssertEqual(textField.text, "a", "Value after binding")
    XCTAssertEqual(label.text, "a", "Value after binding")
    
    dynamicDriver.value = "b"
    
    XCTAssertEqual(bondedValue, "b", "Value after change")
    XCTAssertEqual(textField.text, "b", "Value after change")
    XCTAssertEqual(label.text, "b", "Value after change")
  }
  
  func testTwoWayOperators() {
    let dynamicDriver1 = Dynamic<String>("a")
    let dynamicDriver2 = Dynamic<String>("z")
    let textView1 = UITextView()
    let textView2 = UITextView()
    let textField = UITextField()
    textField.text = "1"
    
    XCTAssertEqual(dynamicDriver1.value, "a", "Initial value")
    XCTAssertEqual(dynamicDriver2.value, "z", "Initial value")
    XCTAssertEqual(textField.text, "1", "Initial value")
    
    dynamicDriver1 <->> textView1
    textView1 <->> textView2
    textView2 <->> dynamicDriver2
    textView2 <->> textField
    
    XCTAssertEqual(dynamicDriver1.value, "a", "Value after binding")
    XCTAssertEqual(dynamicDriver2.value, "a", "Value after binding")
    XCTAssertEqual(textField.text, "a", "Value after binding")
    
    dynamicDriver1.value = "b"
    
    XCTAssertEqual(dynamicDriver1.value, "b", "Value after change")
    XCTAssertEqual(dynamicDriver2.value, "b", "Value after change")
    XCTAssertEqual(textField.text, "b", "Value after change")

    dynamicDriver2.value = "y"
    
    XCTAssertEqual(dynamicDriver1.value, "y", "Value after change")
    XCTAssertEqual(dynamicDriver2.value, "y", "Value after change")
    XCTAssertEqual(textField.text, "y", "Value after change")
    
    textField.text = "2"
    textField.sendActionsForControlEvents(.EditingChanged)
    
    XCTAssertEqual(dynamicDriver1.value, "2", "Value after change")
    XCTAssertEqual(dynamicDriver2.value, "2", "Value after change")
    XCTAssertEqual(textField.text, "2", "Value after change")
  }
}
