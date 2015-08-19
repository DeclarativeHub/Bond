//
//  NSTextViewTests.swift
//  Bond
//
//  Created by Tony Arnold on 16/04/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import Cocoa
import XCTest

class NSTextViewTests: XCTestCase {
  
  func testNSTextViewTextBond() {
    let dynamicDriver = Observable<String>("Hello")
    let textView = NSTextView(frame: NSZeroRect)
    
    textView.string = "Goodbye"
    XCTAssertEqual(textView.string!, "Goodbye", "Initial value")
    
    dynamicDriver.bindTo(textView.bnd_string)
    XCTAssertEqual(textView.string!, "Hello", "Value after binding")
    
    dynamicDriver.value = "Welcome"
    XCTAssertEqual(textView.string!, "Welcome", "Value after dynamic change")
  }
  
  
  func testOneWayOperators() {
    var bondedValue: String = ""
    let dynamicDriver = Observable<String>("a")
    let textView1 = NSTextView()
    let textView2 = NSTextView()
    let textField = NSTextField()
    
    XCTAssertEqual(bondedValue, "", "Initial value")
    XCTAssertEqual(textField.stringValue, "", "Initial value")
    
    dynamicDriver.bindTo(textView1.bnd_string)
    textView1.bnd_string.bindTo(textView2.bnd_string)
    textView2.bnd_string.observe { bondedValue = $0 }
    textView2.bnd_string.bindTo(textField.bnd_text)
    
    XCTAssertEqual(bondedValue, "a", "Value after binding")
    XCTAssertEqual(textField.stringValue, "a", "Value after binding")
    
    dynamicDriver.value = "b"
    
    XCTAssertEqual(bondedValue, "b", "Value after change")
    XCTAssertEqual(textField.stringValue, "b", "Value after change")
  }
  
  func testTwoWayOperators() {
    let dynamicDriver1 = Observable<String>("a")
    let dynamicDriver2 = Observable<String>("z")
    let textView1 = NSTextView()
    let textView2 = NSTextView()
    let textField = NSTextField()
    textField.stringValue = "1"
    
    XCTAssertEqual(dynamicDriver1.value, "a", "Initial value")
    XCTAssertEqual(dynamicDriver2.value, "z", "Initial value")
    XCTAssertEqual(textField.stringValue, "1", "Initial value")
    
    dynamicDriver1.bidirectionalBindTo(textView1.bnd_string)
    textView1.bnd_string.bidirectionalBindTo(textView2.bnd_string)
    textView2.bnd_string.bidirectionalBindTo(dynamicDriver2)
    textView2.bnd_string.bidirectionalBindTo(textField.bnd_text)
    
    XCTAssertEqual(dynamicDriver1.value, "a", "Value after binding")
    XCTAssertEqual(dynamicDriver2.value, "a", "Value after binding")
    XCTAssertEqual(textField.stringValue, "a", "Value after binding")
    
    dynamicDriver1.value = "b"
    
    XCTAssertEqual(dynamicDriver1.value, "b", "Value after change")
    XCTAssertEqual(dynamicDriver2.value, "b", "Value after change")
    XCTAssertEqual(textField.stringValue, "b", "Value after change")
    
    dynamicDriver2.value = "y"
    
    XCTAssertEqual(dynamicDriver1.value, "y", "Value after change")
    XCTAssertEqual(dynamicDriver2.value, "y", "Value after change")
    XCTAssertEqual(textField.stringValue, "y", "Value after change")
  }
}
