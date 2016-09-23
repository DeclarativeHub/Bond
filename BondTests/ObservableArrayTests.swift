//
//  ObservableArrayTests.swift
//  Bond
//
//  Created by Srdan Rasic on 19/09/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import XCTest
@testable import Bond

class ObservableArrayTests: XCTestCase {
  
  var array: MutableObservableArray<Int>!
  
  override func setUp() {
    super.setUp()
    array = MutableObservableArray([1, 2, 3])
  }
  
  func testAppend() {
    array.expectNext([
      ObservableArrayEvent(change: .reset, source: array),
      ObservableArrayEvent(change: .inserts([3]), source: array)
      ])
    
    array.append(4)
    XCTAssert(array == ObservableArray([1, 2, 3, 4]))
  }
  
  func testInsert() {
    array.expectNext([
      ObservableArrayEvent(change: .reset, source: array),
      ObservableArrayEvent(change: .inserts([0]), source: array),
      ObservableArrayEvent(change: .inserts([2]), source: array)
      ])
    
    array.insert(4, at: 0)
    XCTAssert(array == ObservableArray([4, 1, 2, 3]))
    array.insert(5, at: 2)
    XCTAssert(array == ObservableArray([4, 1, 5, 2, 3]))
  }
  
  func testInsertContentsOf() {
    array.expectNext([
      ObservableArrayEvent(change: .reset, source: array),
      ObservableArrayEvent(change: .inserts([1, 2]), source: array),
      ])
    
    array.insert(contentsOf: [4, 5], at: 1)
    XCTAssert(array == ObservableArray([1, 4, 5, 2, 3]))
  }
  
  func testMove() {
    array.expectNext([
      ObservableArrayEvent(change: .reset, source: array),
      ObservableArrayEvent(change: .move(1, 2), source: array),
      ])
    
    array.moveItem(from: 1, to: 2)
    XCTAssert(array == ObservableArray([1, 3, 2]))
  }
  
  
  func testRemoveAtIndex() {
    array.expectNext([
      ObservableArrayEvent(change: .reset, source: array),
      ObservableArrayEvent(change: .deletes([2]), source: array),
      ObservableArrayEvent(change: .deletes([0]), source: array)
      ])
    
    let removed = array.remove(at: 2)
    XCTAssert(array == ObservableArray([1, 2]))
    XCTAssert(removed == 3)
    
    let removed2 = array.remove(at: 0)
    XCTAssert(array == ObservableArray([2]))
    XCTAssert(removed2 == 1)
  }
  
  func testRemoveLast() {
    array.expectNext([
      ObservableArrayEvent(change: .reset, source: array),
      ObservableArrayEvent(change: .deletes([2]), source: array)
      ])
    
    let removed = array.removeLast()
    XCTAssert(removed == 3)
    XCTAssert(array == ObservableArray([1, 2]))
  }
  
  func testRemoveAll() {
    array.expectNext([
      ObservableArrayEvent(change: .reset, source: array),
      ObservableArrayEvent(change: .deletes([0, 1, 2]), source: array)
      ])
    
    array.removeAll()
    XCTAssert(array == ObservableArray([]))
  }
  
  func testUpdate() {
    array.expectNext([
      ObservableArrayEvent(change: .reset, source: array),
      ObservableArrayEvent(change: .updates([1]), source: array)
      ])
    
    array[1] = 4
    XCTAssert(array == ObservableArray([1, 4, 3]))
  }
  
  func testBatchUpdate() {
    array.expectNext([
      ObservableArrayEvent(change: .reset, source: array),
      ObservableArrayEvent(change: .beginBatchEditing, source: array),
      ObservableArrayEvent(change: .updates([1]), source: array),
      ObservableArrayEvent(change: .inserts([3]), source: array),
      ObservableArrayEvent(change: .endBatchEditing, source: array)
      ])
    
    array.batchUpdate { array in
      array[1] = 4
      array.append(5)
    }
    
    XCTAssert(array == ObservableArray([1, 4, 3, 5]))
  }
  
  func testSilentUpdate() {
    array.expectNext([
      ObservableArrayEvent(change: .reset, source: array),
      ])
    
    array.silentUpdate { array in
      array[1] = 4
      array.append(5)
    }
    
    XCTAssert(array == ObservableArray([1, 4, 3, 5]))
  }
}
