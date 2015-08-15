//
//  UITextFieldTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UITextFieldTests: XCTestCase {

  func testUITextFieldScalar() {
    let scalar = Scalar<String>("b")
    let textField = UITextField()
    
    textField.text = "a"
    XCTAssert(textField.text == "a", "Initial value")
    
    scalar.bidirectionalBindTo(textField.bnd_text)
    XCTAssert(textField.text == "b", "Text field value after binding")
    
    scalar.value = "c"
    XCTAssert(textField.text == "c", "Text field value reflects scalar value change")
    
    textField.text = "d"
    textField.sendActionsForControlEvents(.EditingChanged) //simulate user input
    XCTAssertEqual(textField.bnd_text.value, "d", "Scalar value reflects text field value change")
    XCTAssertEqual(scalar.value, "d", "Scalar value reflects text view field change")
  }
    
  func testUITextFieldEnabledBond() {
    let scalar = Scalar<Bool>(false)
    let textField = UITextField()

    textField.enabled = true
    XCTAssert(textField.enabled == true, "Initial value")

    scalar.bindTo(textField.bnd_enabled)
    XCTAssert(textField.enabled == false, "Value after binding")

    scalar.value = true
    XCTAssert(textField.enabled == true, "Value after scalar change")
  }
  
  func testOneWayOperators() {
    var bondedValue = ""
    let scalar = Scalar<String>("a")
    let textField1 = UITextField()
    let textField2 = UITextField()
    let textView = UITextView()
    let label = UILabel()
    
    XCTAssertEqual(bondedValue, "", "Initial value")
    XCTAssertEqual(textView.text, "", "Initial value")
    XCTAssert(label.text == nil, "Initial value")
    
    scalar.bindTo(textField1.bnd_text)
    textField1.bnd_text.bindTo(textField2.bnd_text)
    textField2.bnd_text.observe { bondedValue = $0 }
    textField2.bnd_text.bindTo(textView.bnd_text)
    textField2.bnd_text.bindTo(label.bnd_text)
    
    XCTAssertEqual(bondedValue, "a", "Value after binding")
    XCTAssertEqual(textView.text, "a", "Value after binding")
    XCTAssert(label.text == "a", "Value after binding")
    
    scalar.value = "b"
    
    XCTAssertEqual(bondedValue, "b", "Value after change")
    XCTAssertEqual(textView.text, "b", "Value after change")
    XCTAssert(label.text == "b", "Value after change")
  }
  
  func testTwoWayOperators() {
    let scalar1 = Scalar<String>("a")
    let scalar2 = Scalar<String>("z")
    let textField1 = UITextField()
    let textField2 = UITextField()
    let textView = UITextView()

    XCTAssertEqual(scalar1.value, "a", "Initial value")
    XCTAssertEqual(scalar2.value, "z", "Initial value")

    scalar1.bidirectionalBindTo(textField1.bnd_text)
    textField1.bnd_text.bidirectionalBindTo(textView.bnd_text)
    textView.bnd_text.bidirectionalBindTo(textField2.bnd_text)
    textField2.bnd_text.bidirectionalBindTo(scalar2)
    
    XCTAssertEqual(scalar1.value, "a", "After binding")
    XCTAssertEqual(scalar2.value, "a", "After binding")
    
    scalar1.value = "c"

    XCTAssertEqual(scalar1.value, "c", "Value after change")
    XCTAssertEqual(scalar2.value, "c", "Value after change")
    
    scalar2.value = "y"
    
    XCTAssertEqual(scalar1.value, "y", "Value after change")
    XCTAssertEqual(scalar2.value, "y", "Value after change")
  }
}
