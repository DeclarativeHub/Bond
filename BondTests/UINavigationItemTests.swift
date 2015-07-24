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
        var dynamicDriver = Dynamic<String>("TestTitle")
        let item = UINavigationItem()
        
        XCTAssert(item.title == nil, "Initial value")
        
        dynamicDriver ->> item.dynTitle
        XCTAssert(item.title == "TestTitle", "Value after binding")
        
        dynamicDriver.value = "TestTitle2"
        XCTAssert(item.title == "TestTitle2", "Value after dynamic change")
    }
}
