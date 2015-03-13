//
//  ArrayTests.swift
//  Bond
//
//  Created by Srdan Rasic on 13/03/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import XCTest

class ArrayTests: XCTestCase {
  
  override func setUp() {
    super.setUp()
  }
  
  override func tearDown() {
    super.tearDown()
  }
  
  func testArrayOperations() {
    let array = DynamicArray<Int>([])
    
    XCTAssert(array.count == 0)
    
    array.append(1)
    XCTAssert(array.count == 1)
    XCTAssert(array[0] == 1)
    
    array.append(2)
    XCTAssert(array.count == 2)
    XCTAssert(array.value == [1, 2])
  
    array.insert(3, atIndex: 0)
    XCTAssert(array.count == 3)
    XCTAssert(array.value == [3, 1, 2])
    
    array.append([4, 5])
    XCTAssert(array.count == 5)
    XCTAssert(array.value == [3, 1, 2, 4, 5])
    
    let last = array.removeLast()
    XCTAssert(array.count == 4)
    XCTAssert(array.value == [3, 1, 2, 4])
    XCTAssert(last == 5)
    
    let element = array.removeAtIndex(1)
    XCTAssert(array.count == 3)
    XCTAssert(array.value == [3, 2, 4])
    XCTAssert(element == 1)
    
    array.splice([8, 9], atIndex: 1)
    XCTAssert(array.count == 5)
    XCTAssert(array.value == [3, 8, 9, 2, 4])
    
    array[0] = 0
    XCTAssert(array.count == 5)
    XCTAssert(array.value == [0, 8, 9, 2, 4])

    array.removeAll(true)
    XCTAssert(array.count == 0)
    XCTAssert(array.value == [])
  }
  
  func testArrayBond() {
    let array = DynamicArray<Int>([])
    let bond = ArrayBond<Int>()
    
    var indices: [Int] = []
    var objects: [Int] = []
    
    bond.insertListener = { a, i in
      indices = i
    }
    
    bond.removeListener = { a, i, o in
      indices = i
      objects = o
    }
    
    bond.updateListener = { a, i, o in
      indices = i
      objects = o
    }
    
    array.bindTo(bond)
    
    XCTAssert(array.count == 0)
    
    array.append(1)
    XCTAssert(indices == [0])
    
    array.append(2)
    XCTAssert(indices == [1])
    
    array.insert(3, atIndex: 0)
    XCTAssert(indices == [0])
    
    array.append([4, 5])
    XCTAssert(indices == [3, 4])
    
    let last = array.removeLast()
    XCTAssert(indices == [4])
    XCTAssert(objects == [5])
    
    let element = array.removeAtIndex(1)
    XCTAssert(indices == [1])
    XCTAssert(objects == [1])
    
    array.splice([8, 9], atIndex: 1)
    XCTAssert(indices == [1, 2])
    
    array[0] = 0
    XCTAssert(indices == [0])
    XCTAssert(objects == [3])
    
    array.removeAll(true)
    XCTAssert(indices == [0, 1, 2, 3, 4])
  }
  
  func testArrayFilter() {
    let array = DynamicArray<Int>([])
    let filtered: DynamicArray<Int> = array.filter { $0 > 5 }
    let bond = ArrayBond<Int>()
    
    var indices: [Int] = []
    var removedObjects: [Int] = []
    var updatedObjects: [Int] = []
    
    let resetState = { () -> () in
      indices = []
      removedObjects = []
      updatedObjects = []
    }
    
    bond.insertListener = { a, i in
      indices = i
    }
    
    bond.removeListener = { a, i, o in
      indices = i
      removedObjects = o
    }
    
    bond.updateListener = { a, i, o in
      indices = i
      updatedObjects = o
    }
    
    filtered.bindTo(bond)
    
    XCTAssert(array.count == 0)
    XCTAssert(filtered.value == [])
    resetState()
    
    array.append(1)   // [1]
    XCTAssert(indices == [])
    XCTAssert(filtered.value == [])
    resetState()
    
    array.append(6)   // [1, 6]
    XCTAssert(indices == [0])
    XCTAssert(filtered.value == [6])
    resetState()
    
    array.insert(3, atIndex: 0)   // [3, 1, 6]
    XCTAssert(indices == [])
    XCTAssert(filtered.value == [6])
    resetState()
    
    array.insert(8, atIndex: 1)   // [3, 8, 1, 6]
    XCTAssert(indices == [0])
    XCTAssert(filtered.value == [8, 6])
    resetState()

    array.append([4, 7])  // [3, 8, 1, 6, 4, 7]
    XCTAssert(indices == [2])
    XCTAssert(filtered.value == [8, 6, 7])
    resetState()

    let last = array.removeLast()  // [3, 8, 1, 6, 4]
    XCTAssert(indices == [2])
    XCTAssert(removedObjects == [last])
    XCTAssert(removedObjects == [7])
    XCTAssert(filtered.value == [8, 6])
    resetState()

    let element = array.removeAtIndex(1)   // [3, 1, 6, 4]
    XCTAssert(indices == [0])
    XCTAssert(removedObjects == [element])
    XCTAssert(removedObjects == [8])
    XCTAssert(filtered.value == [6])
    resetState()
    
    array.splice([8, 9, 3], atIndex: 1)   // [3, 8, 9, 3, 1, 6, 4]
    XCTAssert(indices == [0, 1])
    XCTAssert(filtered.value == [8, 9, 6])
    resetState()

    array[0] = 0     // [0, 8, 9, 3, 1, 6, 4]
    XCTAssert(indices == [])
    XCTAssert(removedObjects == [])
    XCTAssert(filtered.value == [8, 9, 6])
    resetState()
    
    array[0] = 10     // [10, 8, 9, 3, 1, 6, 4]
    XCTAssert(indices == [0])
    XCTAssert(filtered.value == [10, 8, 9, 6])
    resetState()
    
    array[0] = 9     // [9, 8, 9, 3, 1, 6, 4]
    XCTAssert(indices == [0])
    XCTAssert(updatedObjects == [10])
    XCTAssert(filtered.value == [9, 8, 9, 6])
    resetState()
    
    array[0] = 3     // [3, 8, 9, 3, 1, 6, 4]
    XCTAssert(indices == [0])
    XCTAssert(removedObjects == [9])
    XCTAssert(filtered.value == [8, 9, 6])
    resetState()
    
    array.removeAll(true)
    XCTAssert(indices == [0, 1, 2])
    XCTAssert(removedObjects == [8, 9, 6])
  }
}
