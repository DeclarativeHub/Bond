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
    let scalar = Scalar<Bool>(false)
    let view = UIView()
    
    view.hidden = true
    XCTAssert(view.hidden == true, "Initial value")
    
    scalar.bindTo(view.bnd_hidden)
    XCTAssert(view.hidden == false, "Value after binding")
    
    scalar.value = true
    XCTAssert(view.hidden == true, "Value after scalar change")
  }
  
  func testUIViewAlphaBond() {
    let scalar = Scalar<CGFloat>(0.1)
    let view = UIView()
    
    view.alpha = 0.0
    XCTAssert(abs(view.alpha - 0.0) < 0.0001, "Initial value")
    
    scalar.bindTo(view.bnd_alpha)
    XCTAssert(abs(view.alpha - 0.1) < 0.0001, "Value after binding")
    
    scalar.value = 0.5
    XCTAssert(abs(view.alpha - 0.5) < 0.0001, "Value after scalar change")
  }
  
  func testUIViewBackgroundColorBond() {
    let scalar = Scalar<UIColor>(UIColor.blackColor())
    let view = UIView()
    
    view.backgroundColor = UIColor.redColor()
    XCTAssert(view.backgroundColor == UIColor.redColor(), "Initial value")
    
    scalar.bindTo(view.bnd_backgroundColor)
    XCTAssert(view.backgroundColor == UIColor.blackColor(), "Value after binding")
    
    scalar.value = UIColor.blueColor()
    XCTAssert(view.backgroundColor == UIColor.blueColor(), "Value after scalar change")
  }
  
  func testUILabelBond() {
    let scalar = Scalar<String>("b")
    let label = UILabel()
    
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
    
    scalar.bindTo(label.bnd_text)
    XCTAssert(label.text == "b", "Value after binding")
    
    scalar.value = "c"
    XCTAssert(label.text == "c", "Value after scalar change")
  }
  
  func testUILabelAttributedTextBond() {
    let scalar = Scalar<NSAttributedString>(NSAttributedString(string: "b"))
    let label = UILabel()
    
    label.text = "a"
    XCTAssert(label.text == "a", "Initial value")
    
    scalar.bindTo(label.bnd_attributedText)
    XCTAssert(label.attributedText!.string == "b", "Value after binding")
    
    scalar.value = NSAttributedString(string: "c")
    XCTAssert(label.attributedText!.string == "c", "Value after scalar change")
  }

  func testUIProgressViewBond() {
    let scalar = Scalar<Float>(0)
    let progressView = UIProgressView()
    
    progressView.progress = 0.1
    XCTAssert(progressView.progress == 0.1, "Initial value")
    
    scalar.bindTo(progressView.bnd_progress)
    XCTAssert(progressView.progress == 0.0, "Value after binding")
    
    scalar.value = 0.5
    XCTAssert(progressView.progress == 0.5, "Value after scalar change")
  }
  
  func testUIImageViewBond() {
    let image = UIImage()
    let scalar = Scalar<UIImage?>(nil)
    let imageView = UIImageView()
    
    imageView.image = image
    XCTAssert(imageView.image == image, "Initial value")
    
    scalar.bindTo(imageView.bnd_image)
    XCTAssert(imageView.image == nil, "Value after binding")
    
    imageView.image = image
    XCTAssert(imageView.image == image, "Value after scalar change")
  }
  
  func testUIButtonEnabledBond() {
    let scalar = Scalar<Bool>(false)
    let button = UIButton()
    
    button.enabled = true
    XCTAssert(button.enabled == true, "Initial value")
    
    scalar.bindTo(button.bnd_enabled)
    XCTAssert(button.enabled == false, "Value after binding")
    
    scalar.value = true
    XCTAssert(button.enabled == true, "Value after scalar change")
  }
  
  func testUIButtonTitleBond() {
    let scalar = Scalar<String>("b")
    let button = UIButton()
    
    button.titleLabel?.text = "a"
    XCTAssert(button.titleLabel?.text == "a", "Initial value")
    
    scalar.bindTo(button.bnd_title)
    XCTAssert(button.titleLabel?.text == "b", "Value after binding")
    
    scalar.value = "c"
    XCTAssert(button.titleLabel?.text == "c", "Value after scalar change")
  }
  
  func testUIBarItemEnabledBond() {
    let scalar = Scalar<Bool>(false)
    let barItem = UIBarButtonItem()
    
    barItem.enabled = true
    XCTAssert(barItem.enabled == true, "Initial value")
    
    scalar.bindTo(barItem.bnd_enabled)
    XCTAssert(barItem.enabled == false, "Value after binding")
    
    scalar.value = true
    XCTAssert(barItem.enabled == true, "Value after scalar change")
  }
  
  func testUIBarItemTitleBond() {
    let scalar = Scalar<String>("b")
    let barItem = UIBarButtonItem()
    
    barItem.title = "a"
    XCTAssert(barItem.title == "a", "Initial value")
    
    scalar.bindTo(barItem.bnd_title)
    XCTAssert(barItem.title == "b", "Value after binding")
    
    scalar.value = "c"
    XCTAssert(barItem.title == "c", "Value after scalar change")
  }
  
  func testUIBarItemImageBond() {
    let image1 = UIImage()
    let image2 = UIImage()
    let scalar = Scalar<UIImage?>(nil)
    let barItem = UIBarButtonItem()
    
    barItem.image = image1
    XCTAssert(barItem.image == image1, "Initial value")
    
    scalar.bindTo(barItem.bnd_image)
    XCTAssert(barItem.image == nil, "Value after binding")
    
    scalar.value = image2
    XCTAssert(barItem.image == image2, "Value after scalar change")
  }
  
  func testUIActivityIndicatorViewHiddenBond() {
    let scalar = Scalar<Bool>(false)
    let view = UIActivityIndicatorView()
    
    view.startAnimating()
    XCTAssert(view.isAnimating() == true, "Initial value")
    
    scalar.bindTo(view.bnd_animating)
    XCTAssert(view.isAnimating() == false, "Value after binding")
    
    scalar.value = true
    XCTAssert(view.isAnimating() == true, "Value after scalar change")
  }
}
