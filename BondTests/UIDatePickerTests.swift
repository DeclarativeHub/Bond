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
  
  func testOneWayOperators() {
    let date1 = NSDate(timeIntervalSince1970: 1)
    let date2 = NSDate(timeIntervalSince1970: 2)
    let date3 = NSDate(timeIntervalSince1970: 3)
    
    var bondedValue = date1
    let bond = Bond { bondedValue = $0 }
    let dynamicDriver = Dynamic<NSDate>(date2)
    let datePicker1 = UIDatePicker()
    let datePicker2 = UIDatePicker()
    
    XCTAssertEqual(bondedValue, date1, "Intial value")
    
    dynamicDriver ->> datePicker1
    datePicker1 ->> datePicker2
    datePicker2 ->> bond
    
    XCTAssertEqual(bondedValue, date2, "Value after binding")
    
    dynamicDriver.value = date3
    
    XCTAssertEqual(bondedValue, date3, "Value after dynamic update")
  }
  
  func testTwoWayOperators() {
    let date1 = NSDate(timeIntervalSince1970: 1)
    let date2 = NSDate(timeIntervalSince1970: 2)
    let date3 = NSDate(timeIntervalSince1970: 3)
    let date4 = NSDate(timeIntervalSince1970: 4)
    
    let dynamicDriver1 = Dynamic<NSDate>(date1)
    let dynamicDriver2 = Dynamic<NSDate>(date2)
    let datePicker1 = UIDatePicker()
    let datePicker2 = UIDatePicker()
    
    XCTAssertEqual(dynamicDriver1.value, date1, "Intial value")
    XCTAssertEqual(dynamicDriver2.value, date2, "Intial value")
    
    dynamicDriver1 <->> datePicker1
    datePicker1 <->> datePicker2
    datePicker2 <->> dynamicDriver2
    
    XCTAssertEqual(dynamicDriver1.value, date1, "Value after binding")
    XCTAssertEqual(dynamicDriver2.value, date1, "Value after binding")
    
    dynamicDriver1.value = date3
    
    XCTAssertEqual(dynamicDriver1.value, date3, "Value after dynamic update")
    XCTAssertEqual(dynamicDriver2.value, date3, "Value after dynamic update")
    
    dynamicDriver2.value = date4
    
    XCTAssertEqual(dynamicDriver1.value, date4, "Value after dynamic update")
    XCTAssertEqual(dynamicDriver2.value, date4, "Value after dynamic update")

  }
}
