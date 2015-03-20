//
//  ArrayTests.swift
//  Bond
//
//  Created by Srdan Rasic on 13/03/15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Bond
import XCTest

func ==<T: Equatable>(dynamicArray: DynamicArray<T>, array: [T]) -> Bool {
  if dynamicArray.count == array.count {
    for i in 0..<array.count {
      if dynamicArray[i] != array[i] {
        return false
      }
    }
    
    return true
  } else {
    return false
  }
}

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
    
    bond.didInsertListener = { a, i in
      indices = i
    }
    
    bond.willRemoveListener = { a, i in
      indices = i
      objects = []; for idx in i { objects.append(a[idx]) }
    }
    
    bond.willUpdateListener = { a, i in
      indices = i
      objects = []; for idx in i { objects.append(a[idx]) }
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
    
    bond.didInsertListener = { a, i in
      indices = i
    }
    
    bond.willRemoveListener = { a, i in
      indices = i
      removedObjects = []; for idx in i { removedObjects.append(a[idx]) }
    }
    
    bond.willUpdateListener = { a, i in
      indices = i
      updatedObjects = []; for idx in i { updatedObjects.append(a[idx]) }
    }
    
    filtered.bindTo(bond)
    
    XCTAssert(array.count == 0)
    XCTAssert(filtered == [])
    resetState()
    
    array.append(1)   // [1]
    XCTAssert(indices == [])
    XCTAssert(filtered == [])
    resetState()
    
    array.append(6)   // [1, 6]
    XCTAssert(indices == [0])
    XCTAssert(filtered == [6])
    resetState()
    
    array.insert(3, atIndex: 0)   // [3, 1, 6]
    XCTAssert(indices == [])
    XCTAssert(filtered == [6])
    resetState()
    
    array.insert(8, atIndex: 1)   // [3, 8, 1, 6]
    XCTAssert(indices == [0])
    XCTAssert(filtered == [8, 6])
    resetState()

    array.append([4, 7])  // [3, 8, 1, 6, 4, 7]
    XCTAssert(indices == [2])
    XCTAssert(filtered == [8, 6, 7])
    resetState()

    let last = array.removeLast()  // [3, 8, 1, 6, 4]
    XCTAssert(indices == [2])
    XCTAssert(removedObjects == [last])
    XCTAssert(removedObjects == [7])
    XCTAssert(filtered == [8, 6])
    resetState()

    let element = array.removeAtIndex(1)   // [3, 1, 6, 4]
    XCTAssert(array.value == [3, 1, 6, 4])
    XCTAssert(indices == [0])
    XCTAssert(removedObjects == [element])
    XCTAssert(removedObjects == [8])
    XCTAssert(filtered == [6])
    resetState()
    
    array.splice([8, 9, 3], atIndex: 1)   // [3, 8, 9, 3, 1, 6, 4]
    XCTAssert(array.value == [3, 8, 9, 3, 1, 6, 4])
    XCTAssert(indices == [0, 1])
    XCTAssert(filtered == [8, 9, 6])
    resetState()

    array[0] = 0     // [0, 8, 9, 3, 1, 6, 4]
    XCTAssert(indices == [])
    XCTAssert(removedObjects == [])
    XCTAssert(filtered == [8, 9, 6])
    resetState()
    
    array[0] = 10     // [10, 8, 9, 3, 1, 6, 4]
    XCTAssert(indices == [0])
    XCTAssert(filtered == [10, 8, 9, 6])
    resetState()
    
    array[0] = 9     // [9, 8, 9, 3, 1, 6, 4]
    XCTAssert(indices == [0])
    XCTAssert(filtered == [9, 8, 9, 6])
    resetState()
    
    array[0] = 3     // [3, 8, 9, 3, 1, 6, 4]
    XCTAssert(indices == [0])
    XCTAssert(filtered == [8, 9, 6])
    resetState()
    
    array.removeAll(true)
    XCTAssert(indices == [0, 1, 2])
    XCTAssert(removedObjects == [8, 9, 6])
  }
  
  func testArrayMap() {
    let array = DynamicArray<Int>([])
    let mapped = array.map { e, i in e * 2 }
    
    XCTAssert(array.count == 0)
    XCTAssert(mapped.count == 0)
    
    array.append(1)
    XCTAssert(mapped.count == 1)
    XCTAssert(mapped[0] == 2)
    
    array.insert(2, atIndex: 0)
    XCTAssert(mapped.count == 2)
    XCTAssert(mapped[0] == 4)
    XCTAssert(mapped[1] == 2)
    
    array.splice([3, 4], atIndex: 1)
    XCTAssert(mapped.count == 4)
    XCTAssert(mapped[0] == 4)
    XCTAssert(mapped[1] == 6)
    XCTAssert(mapped[2] == 8)
    XCTAssert(mapped[3] == 2)
    
    array.removeLast()
    XCTAssert(mapped.count == 3)
    XCTAssert(mapped[0] == 4)
    XCTAssert(mapped[1] == 6)
    XCTAssert(mapped[2] == 8)
    
    array.removeAtIndex(1)
    XCTAssert(mapped.count == 2)
    XCTAssert(mapped[0] == 4)
    XCTAssert(mapped[1] == 8)
    
    array.removeAll(true)
    XCTAssert(mapped.count == 0)
  }
  
  func testArrayMapCallCount() {
    class Test {
      var value: Int
      init(_ value: Int) { self.value = value }
    }
    
    var callCount: Int = 0
    let array = DynamicArray<Int>([])
    let mapped = array.map { e, i -> Test in
      callCount++
      return Test(e)
    }
    
    XCTAssert(mapped.count == 0)
    XCTAssert(callCount == 0)
    
    array.append(1)
    XCTAssert(callCount == 0)
    
    XCTAssert(mapped[0].value == 1)
    XCTAssert(callCount == 1, "Should call")
    
    XCTAssert(mapped[0].value == 1)
    XCTAssert(callCount == 2, "Should call")
    
    array.insert(2, atIndex: 0)
    XCTAssert(callCount == 2)
    
    XCTAssert(mapped[1].value == 1)
    XCTAssert(callCount == 3, "Should call")
    
    XCTAssert(mapped[0].value == 2)
    XCTAssert(callCount == 4, "Should call")
    
    XCTAssert(mapped[0].value == 2)
    XCTAssert(callCount == 5, "Should call")
    
    array.removeAtIndex(0)
    XCTAssert(callCount == 5)
    
    XCTAssert(mapped[0].value == 1)
    XCTAssert(callCount == 6, "Should call")
    
    array.removeLast()
    XCTAssert(callCount == 6)
    
    array.splice([1, 2, 3, 4], atIndex: 0)
    XCTAssert(callCount == 6)
    
    XCTAssert(mapped[1].value == 2)
    XCTAssert(callCount == 7, "Should call")
    
    array.removeAtIndex(1)
    XCTAssert(callCount == 7)
    
    XCTAssert(mapped[1].value == 3)
    XCTAssert(callCount == 8, "Should call")
    
    array.insert(2, atIndex: 1)
    XCTAssert(callCount == 8)
    
    XCTAssert(mapped[2].value == 3)
    XCTAssert(callCount == 9, "Should call")
    
    XCTAssert(mapped[1].value == 2)
    XCTAssert(callCount == 10, "Should call")
    
    XCTAssert(mapped.last!.value == 4)
    XCTAssert(callCount == 11, "Should call")
    
    XCTAssert(mapped.last!.value == 4)
    XCTAssert(callCount == 12, "Should call")
    
    XCTAssert(mapped.first!.value == 1)
    XCTAssert(callCount == 13, "Should call")
    
    XCTAssert(mapped.first!.value == 1)
    XCTAssert(callCount == 14, "Should call")
    
    array.removeAll(true)
    XCTAssert(callCount == 14)
  }
  
  func testFilterMapChain() {
    let array = DynamicArray<Int>([])
    let filtered = array.filter { e in e > 2 }
    let mapped = filtered.map { e, i in e * 2 }
    
    XCTAssert(array.count == 0)
    XCTAssert(mapped.count == 0)
    
    array.append(1)
    XCTAssert(mapped == [])
    
    array.insert(3, atIndex: 0)
    XCTAssert(mapped == [6])
    
    array.splice([1, 4], atIndex: 1)
    XCTAssert(mapped == [6, 8])
    
    array.removeLast()
    XCTAssert(mapped == [6, 8])
    
    array.removeAtIndex(2)
    XCTAssert(mapped == [6])
    
    array.removeAll(true)
    XCTAssert(mapped.count == 0)
  }
}
