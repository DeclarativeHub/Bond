//
//  UIDatePickerTests.swift
//  Bond
//
//  Created by Anthony Egerton on 11/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import UIKit
import XCTest
import Bond

class UIDatePickerTests: XCTestCase {

  func testUIDatePickerDynamic() {
    let date1 = NSDate(timeIntervalSince1970: 10)
    let date2 = NSDate(timeIntervalSince1970: 10000)
    let date3 = NSDate(timeIntervalSince1970: 20000)
    
    var dynamicDriver = Dynamic<NSDate>(date1)
    let datePicker = UIDatePicker()
    
        datePicker.date = date2
        XCTAssert(datePicker.date == date2, "Initial value")
    
        dynamicDriver <->> datePicker.dynDate
        XCTAssert(datePicker.date == date1, "DatePicker value after binding")
    
        dynamicDriver.value = date3
        XCTAssert(datePicker.date == date3, "DatePicker value reflects dynamic value change")
    
        datePicker.dynDate.value = date2 // ideally we should simulate user input
        XCTAssert(dynamicDriver.value == date2, "Dynamic value reflects DatePicker value change")
  }
}
