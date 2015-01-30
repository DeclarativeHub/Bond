//
//  DynamicTests.swift
//  Bond
//
//  Created by Brian Hardy on 1/30/15.
//
//

import UIKit
import XCTest
import Bond

class DynamicTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testValueChangeWithOneListener() {
        let dynamicInt = Dynamic<Int>(0)
        var newValue = NSNotFound
        let intBond = Bond<Int>({ value in
            newValue = value
        })
        dynamicInt.bonds.append(BondBox<Int>(intBond))
        
        // act: change the value to 1
        dynamicInt.value = 1
        
        // assert: newValue should change
        XCTAssertEqual(newValue, 1)
    }

}
