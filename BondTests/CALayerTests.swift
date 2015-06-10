//
//  CALayerTests.swift
//  Bond
//
//  Created by Tony Arnold on 16/04/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import QuartzCore
import XCTest

class CALayerTests: XCTestCase {

    func testCALayerBackgroundColorBond() {
        let dynamicDriver = Dynamic<CGColor!>(CGColorCreateGenericGray(1.0, 1.0))
        let layer = CALayer()

        layer.backgroundColor = CGColorCreateGenericGray(0.4, 1.0)
        XCTAssert(CGColorEqualToColor(layer.backgroundColor, CGColorCreateGenericGray(0.4, 1.0)), "Initial value")

        dynamicDriver ->> layer.dynBackgroundColor
        XCTAssert(CGColorEqualToColor(layer.backgroundColor, CGColorCreateGenericGray(1.0, 1.0)), "Value after binding")

        dynamicDriver.value = CGColorCreateGenericRGB(255, 255, 0, 1)
        XCTAssert(CGColorEqualToColor(layer.backgroundColor, CGColorCreateGenericRGB(255, 255, 0, 1)), "Value after dynamic change")
    }

}
