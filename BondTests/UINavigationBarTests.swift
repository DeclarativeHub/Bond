//
//  UINavigationBarTests.swift
//  Bond
//
//  Created by SatoShunsuke on 2015/08/18.
//  Copyright (c) 2015年 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UINavigationBarTests: XCTestCase {

  func testUINavigationBarBarTintColorBond() {
    var dynamicDriver = Dynamic<UIColor>(UIColor.blackColor())
    var navigationBar = UINavigationBar()

    navigationBar.barTintColor = UIColor.redColor()
    XCTAssert(navigationBar.barTintColor == UIColor.redColor(), "Initial Value")

    dynamicDriver ->> navigationBar.dynBarTintColor
    XCTAssert(navigationBar.barTintColor == UIColor.blackColor(), "Value after binding")

    dynamicDriver.value = UIColor.blueColor()
    XCTAssert(navigationBar.barTintColor == UIColor.blueColor(), "Value after dynamic change")
  }

}
