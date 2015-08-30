//
//  NSObjectTests.swift
//  Bond
//
//  Created by Srdan Rasic on 17/08/15.
//  Copyright © 2015 Bond. All rights reserved.
//

import XCTest
import Foundation
@testable import Bond

@objc class KVOTest: NSObject {
  dynamic var value: String? = "initial"
}

class NSObjectTests: XCTestCase {
  
  func testKVO() {
    let object = KVOTest()
    let observable = Observable<String>(object: object, keyPath: "value")
    
    XCTAssertEqual(object.value, "initial")
    XCTAssertEqual(observable.value, "initial")
    
    object.value = "new"
    XCTAssertEqual(observable.value, "new")
  }
  
  func testKVOAsOptional() {
    let object = KVOTest()
    let observable = Observable<String?>(object: object, keyPath: "value")
    
    XCTAssertEqual(object.value, "initial")
    XCTAssertEqual(observable.value, "initial")
    
    object.value = nil
    XCTAssertEqual(observable.value, nil)
  }
  
  func testKVORetainsTarget() {
    var object: KVOTest! = KVOTest()
    weak var objectWeak: KVOTest! = object
    var observable: Observable<String?>! = Observable<String?>(object: object, keyPath: "value")

    XCTAssert(observable != nil)
    XCTAssert(objectWeak != nil)
    
    object = nil
    XCTAssert(objectWeak != nil, "Object should be retained by the observing Scalar")
    
    observable = nil
    XCTAssert(objectWeak == nil, "Object should now be released")
  }
}
