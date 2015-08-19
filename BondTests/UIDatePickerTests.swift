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
  
  func testUIDatePickerObservable() {
    let date1 = NSDate(timeIntervalSince1970: 10)
    let date2 = NSDate(timeIntervalSince1970: 10000)
    let date3 = NSDate(timeIntervalSince1970: 20000)
    
    let observable = Observable<NSDate>(date1)
    let datePicker = UIDatePicker()
    
    datePicker.date = date2
    XCTAssert(datePicker.date == date2, "Initial value")
    
    observable.bidirectionalBindTo(datePicker.bnd_date)
    XCTAssert(datePicker.date == date1, "DatePicker value after binding")
    
    observable.value = date3
    XCTAssert(datePicker.date == date3, "DatePicker value reflects observable value change")
    
    datePicker.bnd_date.value = date2 // ideally we should simulate user input
    XCTAssert(observable.value == date2, "Observable value reflects DatePicker value change")
  }
  
  func testOneWayOperators() {
    let date1 = NSDate(timeIntervalSince1970: 1)
    let date2 = NSDate(timeIntervalSince1970: 2)
    let date3 = NSDate(timeIntervalSince1970: 3)
    
    var bondedValue = date1
    let observable = Observable<NSDate>(date2)
    let datePicker1 = UIDatePicker()
    let datePicker2 = UIDatePicker()
    
    XCTAssertEqual(bondedValue, date1, "Intial value")
    
    observable.bindTo(datePicker1.bnd_date)
    datePicker1.bnd_date.bindTo(datePicker2.bnd_date)
    
    datePicker2.bnd_date.observe {
      bondedValue = $0
    }
    
    XCTAssertEqual(bondedValue, date2, "Value after binding")
    
    observable.value = date3
    XCTAssertEqual(bondedValue, date3, "Value after observable update")
  }
  
  func testTwoWayOperators() {
    let date1 = NSDate(timeIntervalSince1970: 1)
    let date2 = NSDate(timeIntervalSince1970: 2)
    let date3 = NSDate(timeIntervalSince1970: 3)
    let date4 = NSDate(timeIntervalSince1970: 4)
    
    let observable1 = Observable<NSDate>(date1)
    let observable2 = Observable<NSDate>(date2)
    let datePicker1 = UIDatePicker()
    let datePicker2 = UIDatePicker()
    
    XCTAssertEqual(observable1.value, date1, "Intial value")
    XCTAssertEqual(observable2.value, date2, "Intial value")
    
    observable1.bidirectionalBindTo(datePicker1.bnd_date)
    datePicker1.bnd_date.bidirectionalBindTo(datePicker2.bnd_date)
    datePicker2.bnd_date.bidirectionalBindTo(observable2)
    
    XCTAssertEqual(observable1.value, date1, "Value after binding")
    XCTAssertEqual(observable2.value, date1, "Value after binding")
    
    observable1.value = date3
    
    XCTAssertEqual(observable1.value, date3, "Value after observable update")
    XCTAssertEqual(observable2.value, date3, "Value after observable update")
    
    observable2.value = date4
    
    XCTAssertEqual(observable1.value, date4, "Value after observable update")
    XCTAssertEqual(observable2.value, date4, "Value after observable update")
    
  }
}
