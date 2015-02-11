//
//  UIKitTests.swift
//  Bond
//
//  Created by Srđan Rašić on 11/02/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UIKitTests: XCTestCase {
  
  func testUISliderBond() {
    var dynamicDriver = Dynamic<Float>(0)
    let slider = UISlider()
    
    slider.value = 0.1
    XCTAssert(slider.value == 0.1, "Initial value")
    
    dynamicDriver ->> slider.designatedBond
    XCTAssert(slider.value == 0.0, "Value after binding")
    
    dynamicDriver.value = 0.5
    XCTAssert(slider.value == 0.5, "Value after dynamic change")
  }
  
  func testUILabelBond() {
    var dynamicDriver = Dynamic<String>("b")
    let label = UILabel()
    
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
    
    dynamicDriver ->> label.designatedBond
    XCTAssert(label.text == "b", "Value after binding")
    
    dynamicDriver.value = "c"
    XCTAssert(label.text == "c", "Value after dynamic change")
  }

  func testUIProgressViewBond() {
    var dynamicDriver = Dynamic<Float>(0)
    let progressView = UIProgressView()
    
    progressView.progress = 0.1
    XCTAssert(progressView.progress == 0.1, "Initial value")
    
    dynamicDriver ->> progressView.designatedBond
    XCTAssert(progressView.progress == 0.0, "Value after binding")
    
    dynamicDriver.value = 0.5
    XCTAssert(progressView.progress == 0.5, "Value after dynamic change")
  }
  
  func testUIImageViewBond() {
    let image = UIImage()
    var dynamicDriver = Dynamic<UIImage?>(nil)
    let imageView = UIImageView()
    
    imageView.image = image
    XCTAssert(imageView.image == image, "Initial value")
    
    dynamicDriver ->> imageView.designatedBond
    XCTAssert(imageView.image == nil, "Value after binding")
    
    imageView.image = image
    XCTAssert(imageView.image == image, "Value after dynamic change")
  }
  
  func testUIButtonBond() {
    var dynamicDriver = Dynamic<Bool>(false)
    let button = UIButton()
    
    button.enabled = true
    XCTAssert(button.enabled == true, "Initial value")
    
    dynamicDriver ->> button.designatedBond
    XCTAssert(button.enabled == false, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssert(button.enabled == true, "Value after dynamic change")
  }
  
  func testUISwitchBond() {
    var dynamicDriver = Dynamic<Bool>(false)
    let switchControl = UISwitch()
    
    switchControl.on = true
    XCTAssert(switchControl.on == true, "Initial value")
    
    dynamicDriver ->> switchControl.designatedBond
    XCTAssert(switchControl.on == false, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssert(switchControl.on == true, "Value after dynamic change")
  }
  
  func testUITextFieldBond() {
    var dynamicDriver = Dynamic<String>("b")
    let textField = UITextField()
    
    textField.text = "a"
    XCTAssert(textField.text == "a", "Initial value")
    
    dynamicDriver ->> textField.designatedBond
    XCTAssert(textField.text == "b", "Value after binding")
    
    dynamicDriver.value = "c"
    XCTAssert(textField.text == "c", "Value after dynamic change")
  }
  
  func testUIDatePickerBond() {
    let date1 = NSDate(timeIntervalSince1970: 10)
    let date2 = NSDate(timeIntervalSince1970: 10000)
    let date3 = NSDate(timeIntervalSince1970: 20000)
    
    var dynamicDriver = Dynamic<NSDate>(date1)
    let datePicker = UIDatePicker()
    
    datePicker.date = date2
    XCTAssert(datePicker.date == date2, "Initial value")
    
    dynamicDriver ->> datePicker.designatedBond
    XCTAssert(datePicker.date == date1, "Value after binding")
    
    dynamicDriver.value = date3
    XCTAssert(datePicker.date == date3, "Value after dynamic change")
  }
}
