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
    
    textField.dynText.value = "d" // ideally we should simulate user input
    XCTAssert(textField.dynText.value == "d", "Dynamic value reflects text field value change")
    XCTAssert(dynamicDriver.value == "d", "Dynamic value reflects text view field change")
  }
}
