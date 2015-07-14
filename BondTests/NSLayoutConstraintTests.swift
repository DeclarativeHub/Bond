//
//  NSLayoutConstraintTests.swift
//  Bond
//
//  Created by Tony Xiao on 6/29/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

#if os(iOS)
  import UIKit
  typealias View = UIView
  #else
  import AppKit
  typealias View = NSView
#endif
import XCTest
import Bond

class NSLayoutConstraintTests : XCTestCase {
    
    func testNSLayoutConstraintActiveBond() {
        var dynamicDriver = Dynamic<Bool>(true)
        let view = View()
        let constraint = NSLayoutConstraint(item: view, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 100)
        
        XCTAssert(constraint.active == false, "Initial value")

        dynamicDriver ->> constraint.dynActive
        XCTAssert(constraint.active == true, "Value after binding")

        dynamicDriver.value = false
        XCTAssert(constraint.active == false, "Value after dynamic change")
    }
}
