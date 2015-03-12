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
    
    dynamicDriver <->> slider.dynValue
    XCTAssert(slider.value == 0.0, "Slider value after binding")
    
    dynamicDriver.value = 0.5
    XCTAssert(slider.value == 0.5, "Slider value reflects dynamic value change")
    
    slider.dynValue.value = 0.8 // ideally we should simulate user input
    XCTAssert(dynamicDriver.value == 0.8, "Dynamic value reflects slider value change")
  }
  
  func testUISwitchDynamic() {
    var dynamicDriver = Dynamic<Bool>(false)
    let uiSwitch = UISwitch()
    
    uiSwitch.on = true
    XCTAssert(uiSwitch.on == true, "Initial value")
    
    dynamicDriver <->> uiSwitch.dynOn
    XCTAssert(uiSwitch.on == false, "Switch value after binding")
    
    dynamicDriver.value = true
    XCTAssert(uiSwitch.on == true, "Switch value reflects dynamic value change")
    
    uiSwitch.dynOn.value = false // ideally we should simulate user input
    XCTAssert(dynamicDriver.value == false, "Dynamic value reflects switch value change")
  }
  
  func testUIButtonDynamic() {
    let button = UIButton()
    
    var observedValue = UIControlEvents.AllEvents
    let bond = Bond<UIControlEvents>() { v in observedValue = v }
    
    XCTAssert(button.dynEvent.faulty == true, "Should be faulty initially")
    
    button.dynEvent.filter(==, .TouchUpInside) ->> bond
    XCTAssert(observedValue == UIControlEvents.AllEvents, "Value after binding should not be changed")
    
    button.dynEvent.value = UIControlEvents.TouchDragInside
    XCTAssert(observedValue == UIControlEvents.AllEvents, "Dynamic change does not pass test - should not update observedValue")
    
    button.dynEvent.value = UIControlEvents.TouchUpInside
    XCTAssert(observedValue == UIControlEvents.TouchUpInside, "Dynamic change passes test - should update observedValue")
  }
  
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
  
  func testUIDatePickerDynamic() {
    let date1 = NSDate(timeIntervalSince1970: 10)
    let date2 = NSDate(timeIntervalSince1970: 10000)
    let date3 = NSDate(timeIntervalSince1970: 20000)
    
    var dynamicDriver = Dynamic<NSDate>(date1)
    let datePicker = UIDatePicker()
    
    datePicker.date = date2
    XCTAssert(datePicker.date == date2, "Initial value")
    
    dynamicDriver <->> datePicker.dynDate
    XCTAssert(datePicker.date == date1, "DatePicker value after binding")
    
    dynamicDriver.value = date3
    XCTAssert(datePicker.date == date3, "DatePicker value reflects dynamic value change")
    
    datePicker.dynDate.value = date2 // ideally we should simulate user input
    XCTAssert(dynamicDriver.value == date2, "Dynamic value reflects DatePicker value change")
  }
}
