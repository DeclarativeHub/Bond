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

  func testUITextViewObservable() {
    let observable = Observable<String?>("b")
    let textView = UITextView()
    
    textView.text = "a"
    XCTAssert(textView.text == "a", "Initial value")
    
    observable.bidirectionalBindTo(textView.bnd_text)
    XCTAssert(textView.text == "b", "Text view value after binding")
    
    observable.value = "c"
    XCTAssert(textView.text == "c", "Text view value reflects observable value change")
    
    textView.text = "d"
    NSNotificationCenter.defaultCenter().postNotificationName(UITextViewTextDidChangeNotification, object: textView)
    XCTAssert(textView.bnd_text.value == "d", "Observable value reflects text view value change")
    XCTAssert(observable.value == "d", "Observable value reflects text view value change")
  }
  
  func testUITextViewAttributedObservable() {
    let observable = Observable<NSAttributedString?>(NSAttributedString(string: "b"))
    let textView = UITextView()
    
    textView.attributedText = NSAttributedString(string: "a")
    XCTAssert(textView.attributedText.string == "a", "Initial value")
    
    observable.bidirectionalBindTo(textView.bnd_attributedText)
    XCTAssert(textView.attributedText.string == "b", "Text view value after binding")
    
    observable.value = NSAttributedString(string: "c")
    XCTAssert(textView.attributedText.string == "c", "Text view value reflects observable value change")
    
    textView.attributedText = NSAttributedString(string: "d")
    NSNotificationCenter.defaultCenter().postNotificationName(UITextViewTextDidChangeNotification, object: textView)
    XCTAssert(textView.bnd_attributedText.value == textView.attributedText, "Observable value reflects text view value change")
    XCTAssert(observable.value == textView.attributedText, "Observable value reflects text view value change")
  }
  
  func testOneWayOperators() {
    var bondedValue: String? = ""
    let observable = Observable<String?>("a")
    let textView1 = UITextView()
    let textView2 = UITextView()
    let textField = UITextField()
    let label = UILabel()
    
    XCTAssertEqual(bondedValue, "", "Initial value")
    XCTAssert(textField.text == "", "Initial value")
    XCTAssert(label.text == nil, "Initial value")
    
    observable.bindTo(textView1.bnd_text)
    textView1.bnd_text.bindTo(textView2.bnd_text)
    textView2.bnd_text.observe { bondedValue = $0 }
    textView2.bnd_text.bindTo(textField.bnd_text)
    textView2.bnd_text.bindTo(label.bnd_text)
    
    XCTAssertEqual(bondedValue, "a", "Value after binding")
    XCTAssert(textField.text == "a", "Value after binding")
    XCTAssert(label.text == "a", "Value after binding")
    
    observable.value = "b"
    
    XCTAssertEqual(bondedValue, "b", "Value after change")
    XCTAssert(textField.text == "b", "Value after change")
    XCTAssert(label.text == "b", "Value after change")
  }
  
  func testTwoWayOperators() {
    let observable1 = Observable<String>("a")
    let observable2 = Observable<String>("z")
    let textView1 = UITextView()
    let textView2 = UITextView()
    let textField = UITextField()
    textField.text = "1"
    
    XCTAssertEqual(observable1.value, "a", "Initial value")
    XCTAssertEqual(observable2.value, "z", "Initial value")
    XCTAssert(textField.text == "1", "Initial value")
    
    observable1.bindTo(textView1.bnd_text)
    textView1.bnd_text.ignoreNil().bindTo(observable1)

    textView1.bnd_text.bidirectionalBindTo(textView2.bnd_text)
    
    textView2.bnd_text.ignoreNil().bindTo(observable2)
    observable2.bindTo(textView2.bnd_text)
    
    textView2.bnd_text.bidirectionalBindTo(textField.bnd_text)
    
    XCTAssertEqual(observable1.value, "a", "Value after binding")
    XCTAssertEqual(observable2.value, "a", "Value after binding")
    XCTAssert(textField.text! == "a", "Value after binding")
    
    observable1.value = "b"
    
    XCTAssertEqual(observable1.value, "b", "Value after change")
    XCTAssertEqual(observable2.value, "b", "Value after change")
    XCTAssert(textField.text! == "b", "Value after change")

    observable2.value = "y"
    
    XCTAssertEqual(observable1.value, "y", "Value after change")
    XCTAssertEqual(observable2.value, "y", "Value after change")
    XCTAssert(textField.text! == "y", "Value after change")
    
    textField.text = "2"
    textField.sendActionsForControlEvents(.EditingChanged)
    
    XCTAssertEqual(observable1.value, "2", "Value after change")
    XCTAssertEqual(observable2.value, "2", "Value after change")
    XCTAssert(textField.text! == "2", "Value after change")
  }
}
