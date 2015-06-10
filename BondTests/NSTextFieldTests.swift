//
//  NSTextFieldTests.swift
//  Bond
//
//  Created by Tony Arnold on 16/04/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import Cocoa
import XCTest

class NSTextFieldTests: XCTestCase {

    func testNSTextFieldTextBond() {
        let dynamicDriver = Dynamic<String>("Hello")
        let textField = NSTextField(frame: NSZeroRect)

        textField.stringValue = "Goodbye"
        XCTAssertEqual(textField.stringValue, "Goodbye", "Initial value")

        dynamicDriver ->> textField.dynText
        XCTAssertEqual(textField.stringValue, "Hello", "Value after binding")

        dynamicDriver.value = "Welcome"
        XCTAssertEqual(textField.stringValue, "Welcome", "Value after dynamic change")
    }

    func testOneWayOperators() {
        var bondedValue = ""
        let bond = Bond { bondedValue = $0 }
        let dynamicDriver = Dynamic<String>("a")
        let textField1 = NSTextField()
        let textField2 = NSTextField()
        let textView = NSTextView()

        XCTAssertEqual(bondedValue, "", "Initial value")
        XCTAssertEqual(textView.string!, "", "Initial value")

        dynamicDriver ->> textField1
        textField1 ->> textField2
        textField2 ->> bond
        textField2 ->> textView

        XCTAssertEqual(bondedValue, "a", "Value after binding")
        XCTAssertEqual(textView.string!, "a", "Value after binding")

        dynamicDriver.value = "b"

        XCTAssertEqual(bondedValue, "b", "Value after change")
        XCTAssertEqual(textView.string!, "b", "Value after change")
    }

    func testTwoWayOperators() {
        let dynamicDriver1 = Dynamic<String>("a")
        let dynamicDriver2 = Dynamic<String>("z")
        let textField1 = NSTextField()
        let textField2 = NSTextField()
        let textView = NSTextView()

        XCTAssertEqual(dynamicDriver1.value, "a", "Initial value")
        XCTAssertEqual(dynamicDriver2.value, "z", "Initial value")

        dynamicDriver1 <->> textField1
        textField1 <->> textView
        textView <->> textField2
        textField2 <->> dynamicDriver2

        XCTAssertEqual(dynamicDriver1.value, "a", "After binding")
        XCTAssertEqual(dynamicDriver2.value, "a", "After binding")

        dynamicDriver1.value = "c"

        XCTAssertEqual(dynamicDriver1.value, "c", "Value after change")
        XCTAssertEqual(dynamicDriver2.value, "c", "Value after change")
        
        dynamicDriver2.value = "y"
        
        XCTAssertEqual(dynamicDriver1.value, "y", "Value after change")
        XCTAssertEqual(dynamicDriver2.value, "y", "Value after change")
    }

}
