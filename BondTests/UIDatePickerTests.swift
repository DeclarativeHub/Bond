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
  
  func testUIDatePickerScalar() {
    let date1 = NSDate(timeIntervalSince1970: 10)
    let date2 = NSDate(timeIntervalSince1970: 10000)
    let date3 = NSDate(timeIntervalSince1970: 20000)
    
    let scalar = Scalar<NSDate>(date1)
    let datePicker = UIDatePicker()
    
    datePicker.date = date2
    XCTAssert(datePicker.date == date2, "Initial value")
    
    scalar.bidirectionBindTo(datePicker.bnd_date)
    XCTAssert(datePicker.date == date1, "DatePicker value after binding")
    
    scalar.value = date3
    XCTAssert(datePicker.date == date3, "DatePicker value reflects scalar value change")
    
    datePicker.bnd_date.value = date2 // ideally we should simulate user input
    XCTAssert(scalar.value == date2, "Scalar value reflects DatePicker value change")
  }
  
  func testOneWayOperators() {
    let date1 = NSDate(timeIntervalSince1970: 1)
    let date2 = NSDate(timeIntervalSince1970: 2)
    let date3 = NSDate(timeIntervalSince1970: 3)
    
    var bondedValue = date1
    let scalar = Scalar<NSDate>(date2)
    let datePicker1 = UIDatePicker()
    let datePicker2 = UIDatePicker()
    
    XCTAssertEqual(bondedValue, date1, "Intial value")
    
    scalar.bindTo(datePicker1.bnd_date)
    datePicker1.bnd_date.bindTo(datePicker2.bnd_date)
    
    datePicker2.bnd_date.observe {
      bondedValue = $0
    }
    
    XCTAssertEqual(bondedValue, date2, "Value after binding")
    
    scalar.value = date3
    XCTAssertEqual(bondedValue, date3, "Value after scalar update")
  }
  
  func testTwoWayOperators() {
    let date1 = NSDate(timeIntervalSince1970: 1)
    let date2 = NSDate(timeIntervalSince1970: 2)
    let date3 = NSDate(timeIntervalSince1970: 3)
    let date4 = NSDate(timeIntervalSince1970: 4)
    
    let scalar1 = Scalar<NSDate>(date1)
    let scalar2 = Scalar<NSDate>(date2)
    let datePicker1 = UIDatePicker()
    let datePicker2 = UIDatePicker()
    
    XCTAssertEqual(scalar1.value, date1, "Intial value")
    XCTAssertEqual(scalar2.value, date2, "Intial value")
    
    scalar1.bidirectionBindTo(datePicker1.bnd_date)
    datePicker1.bnd_date.bidirectionBindTo(datePicker2.bnd_date)
    datePicker2.bnd_date.bidirectionBindTo(scalar2)
    
    XCTAssertEqual(scalar1.value, date1, "Value after binding")
    XCTAssertEqual(scalar2.value, date1, "Value after binding")
    
    scalar1.value = date3
    
    XCTAssertEqual(scalar1.value, date3, "Value after scalar update")
    XCTAssertEqual(scalar2.value, date3, "Value after scalar update")
    
    scalar2.value = date4
    
    XCTAssertEqual(scalar1.value, date4, "Value after scalar update")
    XCTAssertEqual(scalar2.value, date4, "Value after scalar update")
    
  }
}
