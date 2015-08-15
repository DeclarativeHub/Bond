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

  func testUITextViewScalar() {
    let scalar = Scalar<String>("b")
    let textView = UITextView()
    
    textView.text = "a"
    XCTAssert(textView.text == "a", "Initial value")
    
    scalar.bidirectionBindTo(textView.bnd_text)
    XCTAssert(textView.text == "b", "Text view value after binding")
    
    scalar.value = "c"
    XCTAssert(textView.text == "c", "Text view value reflects scalar value change")
    
    textView.text = "d"
    NSNotificationCenter.defaultCenter().postNotificationName(UITextViewTextDidChangeNotification, object: textView)
    XCTAssert(textView.bnd_text.value == "d", "Scalar value reflects text view value change")
    XCTAssert(scalar.value == "d", "Scalar value reflects text view value change")
  }
  
  func testUITextViewAttributedScalar() {
    let scalar = Scalar<NSAttributedString>(NSAttributedString(string: "b"))
    let textView = UITextView()
    
    textView.attributedText = NSAttributedString(string: "a")
    XCTAssert(textView.attributedText.string == "a", "Initial value")
    
    scalar.bidirectionBindTo(textView.bnd_attributedText)
    XCTAssert(textView.attributedText.string == "b", "Text view value after binding")
    
    scalar.value = NSAttributedString(string: "c")
    XCTAssert(textView.attributedText.string == "c", "Text view value reflects scalar value change")
    
    textView.attributedText = NSAttributedString(string: "d")
    NSNotificationCenter.defaultCenter().postNotificationName(UITextViewTextDidChangeNotification, object: textView)
    XCTAssert(textView.bnd_attributedText.value.string == "d", "Scalar value reflects text view value change")
    XCTAssert(scalar.value.string == "d", "Scalar value reflects text view value change")
  }
  
  func testOneWayOperators() {
    var bondedValue: String = ""
    let scalar = Scalar<String>("a")
    let textView1 = UITextView()
    let textView2 = UITextView()
    let textField = UITextField()
    let label = UILabel()
    
    XCTAssertEqual(bondedValue, "", "Initial value")
    XCTAssert(textField.text == "", "Initial value")
    XCTAssert(label.text == nil, "Initial value")
    
    scalar.bindTo(textView1.bnd_text)
    textView1.bnd_text.bindTo(textView2.bnd_text)
    textView2.bnd_text.observe { bondedValue = $0 }
    textView2.bnd_text.bindTo(textField.bnd_text)
    textView2.bnd_text.bindTo(label.bnd_text)
    
    XCTAssertEqual(bondedValue, "a", "Value after binding")
    XCTAssert(textField.text == "a", "Value after binding")
    XCTAssert(label.text == "a", "Value after binding")
    
    scalar.value = "b"
    
    XCTAssertEqual(bondedValue, "b", "Value after change")
    XCTAssert(textField.text == "b", "Value after change")
    XCTAssert(label.text == "b", "Value after change")
  }
  
  func testTwoWayOperators() {
    let scalar1 = Scalar<String>("a")
    let scalar2 = Scalar<String>("z")
    let textView1 = UITextView()
    let textView2 = UITextView()
    let textField = UITextField()
    textField.text = "1"
    
    XCTAssertEqual(scalar1.value, "a", "Initial value")
    XCTAssertEqual(scalar2.value, "z", "Initial value")
    XCTAssert(textField.text == "1", "Initial value")
    
    scalar1.bidirectionBindTo(textView1.bnd_text)
    textView1.bnd_text.bidirectionBindTo(textView2.bnd_text)
    textView2.bnd_text.bidirectionBindTo(scalar2)
    textView2.bnd_text.bidirectionBindTo(textField.bnd_text)
    
    XCTAssertEqual(scalar1.value, "a", "Value after binding")
    XCTAssertEqual(scalar2.value, "a", "Value after binding")
    XCTAssert(textField.text == "a", "Value after binding")
    
    scalar1.value = "b"
    
    XCTAssertEqual(scalar1.value, "b", "Value after change")
    XCTAssertEqual(scalar2.value, "b", "Value after change")
    XCTAssert(textField.text == "b", "Value after change")

    scalar2.value = "y"
    
    XCTAssertEqual(scalar1.value, "y", "Value after change")
    XCTAssertEqual(scalar2.value, "y", "Value after change")
    XCTAssert(textField.text == "y", "Value after change")
    
    textField.text = "2"
    textField.sendActionsForControlEvents(.EditingChanged)
    
    XCTAssertEqual(scalar1.value, "2", "Value after change")
    XCTAssertEqual(scalar2.value, "2", "Value after change")
    XCTAssert(textField.text == "2", "Value after change")
  }
}
