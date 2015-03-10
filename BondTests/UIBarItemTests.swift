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
}
