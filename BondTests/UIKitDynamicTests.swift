//
//  UIKitDynamicTests.swift
//  Bond
//
//  Created by Srdan Rasic on 26/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UIKitDynamicTests: XCTestCase {
  func testUISliderDynamic() {
    var dynamicDriver = Dynamic<Float>(0)
    let slider = UISlider()
    
    slider.value = 0.1
    XCTAssert(slider.value == 0.1, "Initial value")
    
    dynamicDriver <->> slider.valueDynamic
    XCTAssert(slider.value == 0.0, "Slider value after binding")
    
    dynamicDriver.value = 0.5
    XCTAssert(slider.value == 0.5, "Slider value reflects dynamic value change")
    
    slider.valueDynamic.value = 0.8
    XCTAssert(dynamicDriver.value == 0.8, "Dynamic value reflects slider value change")
  }
  
  func testUITextViewDynamic() {
    var dynamicDriver = Dynamic<String>("b")
    let textView = UITextView()
    
    textView.text = "a"
    XCTAssert(textView.text == "a", "Initial value")
    
    dynamicDriver <->> textView.textDynamic
    XCTAssert(textView.text == "b", "Text view value after binding")
    
    dynamicDriver.value = "c"
    XCTAssert(textView.text == "c", "Text view value reflects dynamic value change")
    
    textView.text = "d"
    NSNotificationCenter.defaultCenter().postNotificationName(UITextViewTextDidChangeNotification, object: textView)
    XCTAssert(textView.textDynamic.value == "d", "Dynamic value reflects text view value change")
    XCTAssert(dynamicDriver.value == "d", "Dynamic value reflects text view value change")
  }
}
