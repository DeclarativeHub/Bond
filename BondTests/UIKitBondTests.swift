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
    
    dynamicDriver ->> view.dynHidden
    XCTAssert(view.hidden == false, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssert(view.hidden == true, "Value after dynamic change")
  }
  
  func testUIViewAlphaBond() {
    var dynamicDriver = Dynamic<CGFloat>(0.1)
    let view = UIView()
    
    view.alpha = 0.0
    XCTAssert(abs(view.alpha - 0.0) < 0.0001, "Initial value")
    
    dynamicDriver ->> view.dynAlpha
    XCTAssert(abs(view.alpha - 0.1) < 0.0001, "Value after binding")
    
    dynamicDriver.value = 0.5
    XCTAssert(abs(view.alpha - 0.5) < 0.0001, "Value after dynamic change")
  }
  
  func testUIViewBackgroundColorBond() {
    var dynamicDriver = Dynamic<UIColor>(UIColor.blackColor())
    let view = UIView()
    
    view.backgroundColor = UIColor.redColor()
    XCTAssert(view.backgroundColor == UIColor.redColor(), "Initial value")
    
    dynamicDriver ->> view.dynBackgroundColor
    XCTAssert(view.backgroundColor == UIColor.blackColor(), "Value after binding")
    
    dynamicDriver.value = UIColor.blueColor()
    XCTAssert(view.backgroundColor == UIColor.blueColor(), "Value after dynamic change")
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
  
  func testUILabelAttributedTextBond() {
    var dynamicDriver = Dynamic<NSAttributedString>(NSAttributedString(string: "b"))
    let label = UILabel()
    
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
    
    dynamicDriver ->> label.dynAttributedText
    XCTAssert(label.attributedText.string == "b", "Value after binding")
    
    dynamicDriver.value = NSAttributedString(string: "c")
    XCTAssert(label.attributedText.string == "c", "Value after dynamic change")
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
    
    dynamicDriver ->> button.dynTitle
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
    
    dynamicDriver ->> button.dynImageForNormalState
    XCTAssert(button.imageForState(.Normal) == nil, "Value after binding")
    
    dynamicDriver.value = image2
    XCTAssert(button.imageForState(.Normal) == image2, "Value after dynamic change")
  }
  
  func testUIBarItemEnabledBond() {
    var dynamicDriver = Dynamic<Bool>(false)
    let barItem = UIBarButtonItem()
    
    barItem.enabled = true
    XCTAssert(barItem.enabled == true, "Initial value")
    
    dynamicDriver ->> barItem.designatedBond
    XCTAssert(barItem.enabled == false, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssert(barItem.enabled == true, "Value after dynamic change")
  }
  
  func testUIBarItemTitleBond() {
    var dynamicDriver = Dynamic<String>("b")
    let barItem = UIBarButtonItem()
    
    barItem.title = "a"
    XCTAssert(barItem.title == "a", "Initial value")
    
    dynamicDriver ->> barItem.dynTitle
    XCTAssert(barItem.title == "b", "Value after binding")
    
    dynamicDriver.value = "c"
    XCTAssert(barItem.title == "c", "Value after dynamic change")
  }
  
  func testUIBarItemImageBond() {
    let image1 = UIImage()
    let image2 = UIImage()
    var dynamicDriver = Dynamic<UIImage?>(nil)
    let barItem = UIBarButtonItem()
    
    barItem.image = image1
    XCTAssert(barItem.image == image1, "Initial value")
    
    dynamicDriver ->> barItem.dynImage
    XCTAssert(barItem.image == nil, "Value after binding")
    
    dynamicDriver.value = image2
    XCTAssert(barItem.image == image2, "Value after dynamic change")
  }
  
  func testUIActivityIndicatorViewHiddenBond() {
    var dynamicDriver = Dynamic<Bool>(false)
    let view = UIActivityIndicatorView()
    
    view.startAnimating()
    XCTAssert(view.isAnimating() == true, "Initial value")
    
    dynamicDriver ->> view.dynIsAnimating
    XCTAssert(view.isAnimating() == false, "Value after binding")
    
    dynamicDriver.value = true
    XCTAssert(view.isAnimating() == true, "Value after dynamic change")
  }
}
