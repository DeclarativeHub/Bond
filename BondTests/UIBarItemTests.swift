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
    let observable = Observable<Bool>(false)
    let barItem = UIBarButtonItem()
    
    barItem.enabled = true
    XCTAssert(barItem.enabled == true, "Initial value")
    
    observable.bindTo(barItem.bnd_enabled)
    XCTAssert(barItem.enabled == false, "Value after binding")
    
    observable.value = true
    XCTAssert(barItem.enabled == true, "Value after observable change")
  }
  
  func testUIBarItemTitleBond() {
    let observable = Observable<String>("b")
    let barItem = UIBarButtonItem()
    
    barItem.title = "a"
    XCTAssert(barItem.title == "a", "Initial value")
    
    observable.bindTo(barItem.bnd_title)
    XCTAssert(barItem.title == "b", "Value after binding")
    
    observable.value = "c"
    XCTAssert(barItem.title == "c", "Value after observable change")
  }
  
  func testUIBarItemImageBond() {
    let image1 = UIImage()
    let image2 = UIImage()
    let observable = Observable<UIImage?>(nil)
    let barItem = UIBarButtonItem()
    
    barItem.image = image1
    XCTAssert(barItem.image == image1, "Initial value")
    
    observable.bindTo(barItem.bnd_image)
    XCTAssert(barItem.image == nil, "Value after binding")
    
    observable.value = image2
    XCTAssert(barItem.image == image2, "Value after observable change")
  }
}
