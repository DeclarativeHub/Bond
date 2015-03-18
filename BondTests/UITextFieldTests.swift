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

  func testUITextFieldDynamic() {
    var dynamicDriver = Dynamic<String>("b")
    let textField = UITextField()
    
    textField.text = "a"
    XCTAssert(textField.text == "a", "Initial value")
    
    dynamicDriver <->> textField.dynText
    XCTAssert(textField.text == "b", "Text field value after binding")
    
    dynamicDriver.value = "c"
    XCTAssert(textField.text == "c", "Text field value reflects dynamic value change")
    
    textField.text = "d"
    textField.sendActionsForControlEvents(.EditingChanged) //simulate user input
    XCTAssertEqual(textField.dynText.value, "d", "Dynamic value reflects text field value change")
    XCTAssertEqual(dynamicDriver.value, "d", "Dynamic value reflects text view field change")
  }
  
  func testOneWayOperators() {
    var bondedValue = ""
    let bond = Bond { bondedValue = $0 }
    let dynamicDriver = Dynamic<String>("a")
    let textField1 = UITextField()
    let textField2 = UITextField()
    let textView = UITextView()
    let label = UILabel()
    
    XCTAssertEqual(bondedValue, "", "Initial value")
    XCTAssertEqual(textView.text, "", "Initial value")
    XCTAssertEqual(label.text, nil, "Initial value")
    
    dynamicDriver ->> textField1
    textField1 ->> textField2
    textField2 ->> bond
    textField2 ->> textView
    textField2 ->> label
    
    XCTAssertEqual(bondedValue, "a", "Value after binding")
    XCTAssertEqual(textView.text, "a", "Value after binding")
    XCTAssertEqual(label.text, "a", "Value after binding")
    
    dynamicDriver.value = "b"
    
    XCTAssertEqual(bondedValue, "b", "Value after change")
    XCTAssertEqual(textView.text, "b", "Value after change")
    XCTAssertEqual(label.text, "b", "Value after change")
  }
  
  func testTwoWayOperators() {
    let dynamicDriver1 = Dynamic<String>("a")
    let dynamicDriver2 = Dynamic<String>("z")
    let textField1 = UITextField()
    let textField2 = UITextField()
    let textView = UITextView()

    XCTAssertEqual(dynamicDriver1.value, "a", "Initial value")
    XCTAssertEqual(dynamicDriver2.value, "z", "Initial value")

    dynamicDriver1 <->> textField1
    textField1 <->> textView
    textView <->> textField2
    textField2 <->> dynamicDriver2
    
    XCTAssertEqual(dynamicDriver1.value, "a", "After binding")
    XCTAssertEqual(dynamicDriver2.value, "a", "After binding")
    
    dynamicDriver1.value = "c"

    XCTAssertEqual(dynamicDriver1.value, "c", "Value after change")
    XCTAssertEqual(dynamicDriver2.value, "c", "Value after change")
    
    dynamicDriver2.value = "y"
    
    XCTAssertEqual(dynamicDriver1.value, "y", "Value after change")
    XCTAssertEqual(dynamicDriver2.value, "y", "Value after change")
  }
}
