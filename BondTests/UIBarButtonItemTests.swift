//
//  UIBarButtonItemTests.swift
//  Bond
//
//  Created by Ivan Sergeyenko on 2015-11-20.
//  Copyright © 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
@testable import Bond


class UIBarButtonItemTests: XCTestCase {
  
  func testUIBarButtonItemObservable() {
    let button = UIBarButtonItem()
    var tapObserved = false

    button.bnd_tap.observe {
      tapObserved = true
    }

    XCTAssert(tapObserved == false, "Value after binding should not be changed")

    UIApplication.sharedApplication().sendAction(button.action, to: button.target, from: nil, forEvent: nil)

    XCTAssert(tapObserved == true, "Should update value after action is fired")
  }
}
