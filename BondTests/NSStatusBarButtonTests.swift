//
//  NSStatusBarButtonTests.swift
//  Bond
//
//  Created by Tony Arnold on 16/04/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import Cocoa
import XCTest

class NSStatusBarButtonTests: XCTestCase {

    func testNSStatusBarButtonAppearsDisabledBond() {
        let dynamicDriver = Dynamic<Bool>(false)
        let statusBarButton = NSStatusBarButton()

        statusBarButton.appearsDisabled = true
        XCTAssertTrue(statusBarButton.appearsDisabled, "Initial value")

        dynamicDriver ->> statusBarButton.dynAppearsDisabled
        XCTAssertFalse(statusBarButton.appearsDisabled, "Value after binding")

        dynamicDriver.value = true
        XCTAssertTrue(statusBarButton.appearsDisabled, "Value after dynamic change")
    }

}
