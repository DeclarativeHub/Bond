//
//  FoundationTests.swift
//  Bond
//
//  Created by Srdan Rasic on 04/03/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import XCTest
import Bond

@objc class User: NSObject {
  dynamic var name: NSString?
  dynamic var height: NSNumber = NSNumber(float: 0.0)
  
  init(name: NSString?) {
    self.name = name
    super.init()
  }
}

class FoundationTests: XCTestCase {
  
  func testKVO() {
    let user = User(name: nil)
    let dynamic: Dynamic<String> = dynamicObservableFor(user, keyPath: "name", defaultValue: "")
    
    XCTAssert(dynamic.value == "", "Value after initialization.")
    
    user.name = "Spock"
    XCTAssert(dynamic.value == "Spock", "Value after property change.")
    
    user.name = nil
    XCTAssert(dynamic.value == "", "Value after property change.")
  }
  
  func testKVO2() {
    let user = User(name: nil)
    let dynamic: Dynamic<String?> = dynamicObservableFor(user, keyPath: "name", from: { $0 as? String }, to: { $0 })
    
    XCTAssert(dynamic.value == nil, "Value after initialization.")
    
    user.name = "Spock"
    XCTAssert(dynamic.value == "Spock", "Value after property change.")
  
    user.name = nil
    XCTAssert(dynamic.value == nil, "Value after property change.")
    
    dynamic.value = "Jim"
    XCTAssert(user.name == "Jim", "Value after dynamic change.")
  }
  
  func testKVO3() {
    let user = User(name: nil)
    let dynamic: Dynamic<String> = dynamicObservableFor(user, keyPath: "name", from: { ($0 as? String) ?? "" }, to: { $0 })
    
    XCTAssert(dynamic.value == "", "Value after initialization.")
    
    user.name = "Spock"
    XCTAssert(dynamic.value == "Spock", "Value after property change.")
    
    user.name = nil
    XCTAssert(dynamic.value == "", "Value after property change.")
    
    dynamic.value = "Jim"
    XCTAssert(user.name == "Jim", "Value after dynamic change.")
  }
  
  func testKVO4() {
    let user = User(name: nil)
    let height: Dynamic<Float> = dynamicObservableFor(user, keyPath: "height", from: { ($0 as NSNumber).floatValue }, to: { NSNumber(float: $0) })
    
    XCTAssert(abs(height.value - 0) < 0.0001, "Value after initialization.")
    
    user.height = 6.9
    XCTAssert(abs(height.value - 6.9) < 0.0001, "Value after property change.")
    
    height.value = 7.1
    XCTAssert(abs(user.height.floatValue - 7.1) < 0.0001, "Value after dynamic change.")
  }
}
