//
//  Observable2DArrayTests.swift
//  Bond
//
//  Created by MOHAMMAD TAWEEL on 1/11/17.
//  Copyright © 2017 Swift Bond. All rights reserved.
//

import Foundation

import XCTest
@testable import Bond

class Observable2DArrayTests: XCTestCase {
  
  var array2D: MutableObservable2DArray<String,Int>!
  
  override func setUp() {
    super.setUp()
    array2D = MutableObservable2DArray([
      Observable2DArraySection(metadata: "units", items: [1,2,3]),
      Observable2DArraySection(metadata: "tens", items: [10,20,30]),
      Observable2DArraySection(metadata: "hundreds", items: [100,200,300]),
      Observable2DArraySection(metadata: "thousands", items: [1000,2000,3000]),
    ])
  }
  
  func testReplace2D() {
    
    let newArray = MutableObservable2DArray([
      Observable2DArraySection(metadata: "tens", items: [10,30]),
      Observable2DArraySection(metadata: "hundreds", items: [100,200,400]),
      Observable2DArraySection(metadata: "hundredssss", items: [100,200,400]),
      Observable2DArraySection(metadata: "units", items: [4,3,2]),
      ])
    
    array2D.replace2D(with: newArray, performDiff: true)
    print(array2D)
//    array.expectNext([
//      ObservableArrayEvent(change: .reset, source: array),
//      ObservableArrayEvent(change: .inserts([3]), source: array)
//      ])
//    
//    array.append(4)
//    XCTAssert(array == ObservableArray([1, 2, 3, 4]))
}

}
