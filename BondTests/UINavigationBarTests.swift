//
//  UINavigationBarTests.swift
//  Bond
//
//  Created by SatoShunsuke on 2015/10/23.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UINavigationBarTests : XCTestCase {

  func testUINavigationBarBarTintColorBond() {
    let observable = Observable<UIColor>(UIColor.blackColor())
    let bar = UINavigationBar()

    bar.barTintColor = UIColor.redColor()
    XCTAssert(bar.barTintColor == UIColor.redColor(), "Initial value")

    observable.bindTo(bar.bnd_barTintColor)
    XCTAssert(bar.barTintColor == UIColor.blackColor(), "Value after binding")

    observable.value = UIColor.blueColor()
    XCTAssert(bar.barTintColor == UIColor.blueColor(), "Value after observable change")
  }
}
