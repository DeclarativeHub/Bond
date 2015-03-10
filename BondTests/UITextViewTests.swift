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
  

}
