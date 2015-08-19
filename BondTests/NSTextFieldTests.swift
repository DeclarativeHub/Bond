//
//  NSTextFieldTests.swift
//  Bond
//
//  Created by Tony Arnold on 16/04/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import Cocoa
import XCTest

class NSTextFieldTests: XCTestCase {
  
  func testNSTextFieldTextBond() {
    let dynamicDriver = Observable<String>("Hello")
    let textField = NSTextField(frame: NSZeroRect)
    
    textField.stringValue = "Goodbye"
    XCTAssertEqual(textField.stringValue, "Goodbye", "Initial value")
    
    dynamicDriver.bindTo(textField.bnd_text)
    XCTAssertEqual(textField.stringValue, "Hello", "Value after binding")
    
    dynamicDriver.value = "Welcome"
    XCTAssertEqual(textField.stringValue, "Welcome", "Value after dynamic change")
  }
  
  func testOneWayOperators() {
    var bondedValue = ""
    let dynamicDriver = Observable<String>("a")
    let textField1 = NSTextField()
    let textField2 = NSTextField()
    let textView = NSTextView()
    
    XCTAssertEqual(bondedValue, "", "Initial value")
    XCTAssertEqual(textView.string!, "", "Initial value")
    
    dynamicDriver.bindTo(textField1.bnd_text)
    textField1.bnd_text.bindTo(textField2.bnd_text)
    textField2.bnd_text.observe { text in bondedValue = text }
    textField2.bnd_text.bindTo(textView.bnd_string)
    
    XCTAssertEqual(bondedValue, "a", "Value after binding")
    XCTAssertEqual(textView.string!, "a", "Value after binding")
    
    dynamicDriver.value = "b"
    
    XCTAssertEqual(bondedValue, "b", "Value after change")
    XCTAssertEqual(textView.string!, "b", "Value after change")
  }
  
  func testTwoWayOperators() {
    let dynamicDriver1 = Observable<String>("a")
    let dynamicDriver2 = Observable<String>("z")
    let textField1 = NSTextField()
    let textField2 = NSTextField()
    let textView = NSTextView()
    
    XCTAssertEqual(dynamicDriver1.value, "a", "Initial value")
    XCTAssertEqual(dynamicDriver2.value, "z", "Initial value")
    
    dynamicDriver1.bidirectionalBindTo(textField1.bnd_text)
    textField1.bnd_text.bidirectionalBindTo(textView.bnd_string)
    textView.bnd_string.bidirectionalBindTo(textField2.bnd_text)
    textField2.bnd_text.bidirectionalBindTo(dynamicDriver2)
    
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
