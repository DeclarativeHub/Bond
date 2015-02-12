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
  
  func testUIViewHiddenBond() {
    var dynamicDriver = Dynamic<Bool>(false)
    let view = UIView()
    
    view.hidden = true
    XCTAssert(view.hidden == true, "Initial value")
    
    dynamicDriver ->> view.hiddenBond
    XCTAssert(view.hidden == false, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssert(view.hidden == true, "Value after dynamic change")
  }
  
  func testUIViewAlphaBond() {
    var dynamicDriver = Dynamic<CGFloat>(0.1)
    let view = UIView()
    
    view.alpha = 0.0
    XCTAssert(abs(view.alpha - 0.0) < 0.0001, "Initial value")
    
    dynamicDriver ->> view.alphaBond
    XCTAssert(abs(view.alpha - 0.1) < 0.0001, "Value after binding")
    
    dynamicDriver.value = 0.5
    XCTAssert(abs(view.alpha - 0.5) < 0.0001, "Value after dynamic change")
  }
  
  func testUIViewBackgroundColorBond() {
    var dynamicDriver = Dynamic<UIColor>(UIColor.blackColor())
    let view = UIView()
    
    view.backgroundColor = UIColor.redColor()
    XCTAssert(view.backgroundColor == UIColor.redColor(), "Initial value")
    
    dynamicDriver ->> view.backgroundColorBond
    XCTAssert(view.backgroundColor == UIColor.blackColor(), "Value after binding")
    
    dynamicDriver.value = UIColor.blueColor()
    XCTAssert(view.backgroundColor == UIColor.blueColor(), "Value after dynamic change")
  }
  
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
  
  func testUIButtonEnabledBond() {
    var dynamicDriver = Dynamic<Bool>(false)
    let button = UIButton()
    
    button.enabled = true
    XCTAssert(button.enabled == true, "Initial value")
    
    dynamicDriver ->> button.designatedBond
    XCTAssert(button.enabled == false, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssert(button.enabled == true, "Value after dynamic change")
  }
  
  func testUIButtonTitleBond() {
    var dynamicDriver = Dynamic<String>("b")
    let button = UIButton()
    
    button.titleLabel?.text = "a"
    XCTAssert(button.titleLabel?.text == "a", "Initial value")
    
    dynamicDriver ->> button.titleBond
    XCTAssert(button.titleLabel?.text == "b", "Value after binding")
    
    dynamicDriver.value = "c"
    XCTAssert(button.titleLabel?.text == "c", "Value after dynamic change")
  }
  
  func testUIButtonImageBond() {
    let image1 = UIImage()
    let image2 = UIImage()
    var dynamicDriver = Dynamic<UIImage?>(nil)
    let button = UIButton()
    
    button.setImage(image1, forState: .Normal)
    XCTAssert(button.imageForState(.Normal) == image1, "Initial value")
    
    dynamicDriver ->> button.imageForNormalStateBond
    XCTAssert(button.imageForState(.Normal) == nil, "Value after binding")
    
    dynamicDriver.value = image2
    XCTAssert(button.imageForState(.Normal) == image2, "Value after dynamic change")
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
