//
//  UIBarItemTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UIBarItemTests: XCTestCase {

  func testUIBarItemEnabledBond() {
    let scalar = Scalar<Bool>(false)
    let barItem = UIBarButtonItem()
    
    barItem.enabled = true
    XCTAssert(barItem.enabled == true, "Initial value")
    
    scalar |> barItem.bnd_enabled
    XCTAssert(barItem.enabled == false, "Value after binding")
    
    scalar.value = true
    XCTAssert(barItem.enabled == true, "Value after scalar change")
  }
  
  func testUIBarItemTitleBond() {
    let scalar = Scalar<String>("b")
    let barItem = UIBarButtonItem()
    
    barItem.title = "a"
    XCTAssert(barItem.title == "a", "Initial value")
    
    scalar |> barItem.bnd_title
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
    
    scalar |> barItem.bnd_image
    XCTAssert(barItem.image == nil, "Value after binding")
    
    scalar.value = image2
    XCTAssert(barItem.image == image2, "Value after scalar change")
  }
}
