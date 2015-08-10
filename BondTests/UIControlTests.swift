//
//  UIControlTests.swift
//  Bond
//
//  Created by Srđan Rašić on 20/07/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import UIKit
import XCTest
@testable import Bond

class UIControlTests: XCTestCase {
  
  func test_bnd_eventObservable() {
    let control = UIControl()
    var observedEvent: UIControlEvents = UIControlEvents.AllEvents
    
    control.bnd_controlEvent.observe { event  in
      observedEvent = event
    }
    
    XCTAssert(observedEvent == UIControlEvents.AllEvents)
    
    control.sendActionsForControlEvents(.TouchDown)
    XCTAssert(observedEvent == UIControlEvents.TouchDown)
  }
}
