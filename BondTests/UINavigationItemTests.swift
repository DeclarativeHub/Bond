//
//  UINavigationItemTests.swift
//  Bond
//
//  Created by Tony Xiao on 6/29/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UINavigationItemTests : XCTestCase {
    
    func testUINavigationItemTitleBond() {
        let scalar = Scalar<String>("TestTitle")
        let item = UINavigationItem()
        
        XCTAssert(item.title == nil, "Initial value")
        
        scalar |> item.bnd_title
        XCTAssert(item.title == "TestTitle", "Value after binding")
        
        scalar.value = "TestTitle2"
        XCTAssert(item.title == "TestTitle2", "Value after scalar change")
    }
}
