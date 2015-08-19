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

  func testUITextFieldObservable() {
    let observable = Observable<String?>("b")
    let textField = UITextField()
    
    textField.text = "a"
    XCTAssert(textField.text == "a", "Initial value")
    
    observable.bidirectionalBindTo(textField.bnd_text)
    XCTAssert(textField.text == "b", "Text field value after binding")
    
    observable.value = "c"
    XCTAssert(textField.text == "c", "Text field value reflects observable value change")
    
    textField.text = "d"
    textField.sendActionsForControlEvents(.EditingChanged) //simulate user input
    XCTAssertEqual(textField.bnd_text.value, "d", "Observable value reflects text field value change")
    XCTAssertEqual(observable.value, "d", "Observable value reflects text view field change")
  }
    
  func testUITextFieldEnabledBond() {
    let observable = Observable<Bool>(false)
    let textField = UITextField()

    textField.enabled = true
    XCTAssert(textField.enabled == true, "Initial value")

    observable.bindTo(textField.bnd_enabled)
    XCTAssert(textField.enabled == false, "Value after binding")

    observable.value = true
    XCTAssert(textField.enabled == true, "Value after observable change")
  }
  
  func testOneWayOperators() {
    var bondedValue: String? = ""
    let observable = Observable<String?>("a")
    let textField1 = UITextField()
    let textField2 = UITextField()
    let textView = UITextView()
    let label = UILabel()
    
    XCTAssertEqual(bondedValue, "", "Initial value")
    XCTAssertEqual(textView.text, "", "Initial value")
    XCTAssert(label.text == nil, "Initial value")
    
    observable.bindTo(textField1.bnd_text)
    textField1.bnd_text.bindTo(textField2.bnd_text)
    textField2.bnd_text.observe { bondedValue = $0 }
    textField2.bnd_text.bindTo(textView.bnd_text)
    textField2.bnd_text.bindTo(label.bnd_text)
    
    XCTAssertEqual(bondedValue, "a", "Value after binding")
    XCTAssertEqual(textView.text, "a", "Value after binding")
    XCTAssert(label.text == "a", "Value after binding")
    
    observable.value = "b"
    
    XCTAssertEqual(bondedValue, "b", "Value after change")
    XCTAssertEqual(textView.text, "b", "Value after change")
    XCTAssert(label.text == "b", "Value after change")
  }
  
  func testTwoWayOperators() {
    let observable1 = Observable<String?>("a")
    let observable2 = Observable<String?>("z")
    let textField1 = UITextField()
    let textField2 = UITextField()
    let textView = UITextView()

    XCTAssertEqual(observable1.value, "a", "Initial value")
    XCTAssertEqual(observable2.value, "z", "Initial value")

    observable1.bidirectionalBindTo(textField1.bnd_text)
    textField1.bnd_text.bidirectionalBindTo(textView.bnd_text)
    textView.bnd_text.bidirectionalBindTo(textField2.bnd_text)
    textField2.bnd_text.bidirectionalBindTo(observable2)
    
    XCTAssertEqual(observable1.value, "a", "After binding")
    XCTAssertEqual(observable2.value, "a", "After binding")
    
    observable1.value = "c"

    XCTAssertEqual(observable1.value, "c", "Value after change")
    XCTAssertEqual(observable2.value, "c", "Value after change")
    
    observable2.value = "y"
    
    XCTAssertEqual(observable1.value, "y", "Value after change")
    XCTAssertEqual(observable2.value, "y", "Value after change")
  }
}
