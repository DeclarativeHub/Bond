//
//  ObservableArrayTests.swift
//  Bond
//
//  Created by Srdan Rasic on 31/07/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import Bond

class ObservableArrayTests: XCTestCase {
  
  func testObservableArrayOperations() {
    let array = ObservableArray<Int>([])
    
    XCTAssert(array.count == 0)
    
    array.append(1)
    XCTAssert(array.count == 1)
    XCTAssert(array[0] == 1)
    
    array.append(2)
    XCTAssert(array.count == 2)
    XCTAssert(array.array == [1, 2])
    
    array.insert(3, atIndex: 0)
    XCTAssert(array.count == 3)
    XCTAssert(array.array == [3, 1, 2])
    
    array.extend([4, 5])
    XCTAssert(array.count == 5)
    XCTAssert(array.array == [3, 1, 2, 4, 5])
    
    let last = array.removeLast()
    XCTAssert(array.count == 4)
    XCTAssert(array.array == [3, 1, 2, 4])
    XCTAssert(last == 5)
    
    let element = array.removeAtIndex(1)
    XCTAssert(array.count == 3)
    XCTAssert(array.array == [3, 2, 4])
    XCTAssert(element == 1)
    
    array.insertContentsOf([8, 9], atIndex: 1)
    XCTAssert(array.count == 5)
    XCTAssert(array.array == [3, 8, 9, 2, 4])
    
    array[0] = 0
    XCTAssert(array.count == 5)
    XCTAssert(array.array == [0, 8, 9, 2, 4])
    
    array.removeAll()
    XCTAssert(array.count == 0)
    XCTAssert(array.array == [])
  }
  
  func testObservableArrayFilter() {
    let array = ObservableArray<Int>([1, 2, 3])
    
    let filtered = array
      .filter { e in e % 2 == 0 }
      .crystallize()
    
    XCTAssert(array.count == 3)
    XCTAssert(filtered.count == 1)
    
    array.append(4) // 1, 2, 3, 4
    XCTAssert(filtered.array == [2, 4])
    
    array.insert(6, atIndex: 0) // 6, 1, 2, 3, 4
    XCTAssert(filtered.array == [6, 2, 4])
    
    array.insert(8, atIndex: 2) // 6, 1, 8, 2, 3, 4
    XCTAssert(filtered.array == [6, 8, 2, 4])
    
    array.removeLast() // 6, 1, 8, 2, 3
    XCTAssert(filtered.array == [6, 8, 2])
    
    array.removeAtIndex(1) // 6, 8, 2, 3
    XCTAssert(filtered.array == [6, 8, 2])
    
    array.removeAtIndex(0) // 8, 2, 3
    XCTAssert(filtered.array == [8, 2])
    
    array.removeRange(1...2) // 8
    XCTAssert(filtered.array == [8])
    
    array.insertContentsOf([3, 4, 5], atIndex: 0) // 3, 4, 5, 8
    XCTAssert(filtered.array == [4, 8])
    
    array.insert(6, atIndex: 2) // 3, 4, 6, 5, 8
    XCTAssert(filtered.array == [4, 6, 8])
    
    array[0] = 1 // 1, 4, 6, 5, 8
    XCTAssert(filtered.array == [4, 6, 8])
    
    array[0] = 2 // 2, 4, 6, 5, 8
    XCTAssert(filtered.array == [2, 4, 6, 8])
    
    array.insert(6, atIndex: 0) // 6, 2, 4, 6, 5, 8
    XCTAssert(filtered.array == [6, 2, 4, 6, 8])
    
    array[1] = 1 // 6, 1, 4, 6, 5, 8
    XCTAssert(filtered.array == [6, 4, 6, 8])
    
    array.removeAtIndex(2) // 6, 1, 6, 5, 8
    XCTAssert(filtered.array == [6, 6, 8])
    
    array[3] = 4 // 6, 1, 6, 4, 8
    XCTAssert(filtered.array == [6, 6, 4, 8])
    
    array.removeRange(1..<array.count) // 6
    XCTAssert(filtered.array == [6])
    
    array.append(1) // 6, 1
    XCTAssert(filtered.array == [6])
    
    array.removeAll() // []
    XCTAssert(filtered.array == [])
    
    array.extend([1, 2, 3, 4]) // 1, 2, 3, 4
    XCTAssert(filtered.array == [2, 4])
    
    array.performBatchUpdates { array in
      array.append(6) // 1, 2, 3, 4, 6
      array[1] = 1 // 1, 1, 3, 4, 6
    }
    XCTAssert(filtered.array == [4, 6])
  }
  
  func testObservableArrayMap() {
    let array = ObservableArray<Int>([])
    
    let mapped = array
      .map { e in e * 2 }
      .crystallize()
    
    XCTAssert(array.count == 0)
    XCTAssert(mapped.count == 0)
    
    array.append(1)
    XCTAssert(mapped.array == [2])
    
    array.insert(2, atIndex: 0)
    XCTAssert(mapped.array == [4, 2])
    
    array.insertContentsOf([3, 4], atIndex: 1)
    XCTAssert(mapped.array == [4, 6, 8, 2])
    
    array.removeLast()
    XCTAssert(mapped.array == [4, 6, 8])
    
    array.removeAtIndex(1)
    XCTAssert(mapped.array == [4, 8])
    
    array.performBatchUpdates { array in
      array.removeAll()
      array.append(2)
      array.insert(1, atIndex: 0)
      array[1] = 4
    }
    XCTAssert(mapped.array == [2, 8])
  }
  
  func testArrayMapCallCount() {
    class Test {
      var value: Int
      init(_ value: Int) { self.value = value }
    }
    
    var callCount: Int = 0
    let array = ObservableArray<Int>([])
    
    let mapped = array
      .map { e -> Test in
        callCount += 1
        return Test(e)
      }
    
    XCTAssert(callCount == 0)
    
    array.append(1)
    XCTAssert(callCount == 1)
    
    array.insert(2, atIndex: 0)
    XCTAssert(callCount == 2)
    
    array.removeAtIndex(0)
    XCTAssert(callCount == 2)
    
    array.removeLast()
    XCTAssert(callCount == 2)
    
    array.insertContentsOf([1, 2, 3, 4], atIndex: 0)
    XCTAssert(callCount == 6)

    array.removeAtIndex(1)
    XCTAssert(callCount == 6)
    
    array.insert(2, atIndex: 1)
    XCTAssert(callCount == 7)
    
    mapped.observe { arrayEvent in
      arrayEvent.sequence.first // just access any element
    }
    
    XCTAssert(callCount == 8)
    
    array.removeAll()
    XCTAssert(callCount == 8)
  }
  
  func testObservableArrayMapCrystallizeCorrectAndDoesNotAffectCallCount() {
    class Test {
      var value: Int
      init(_ value: Int) { self.value = value }
    }
    
    var callCount: Int = 0
    let array = ObservableArray<Int>([])
    
    let mapped = array
      .map { e -> Test in
        callCount += 1
        return Test(e)
      }
      .crystallize()
    
    XCTAssert(mapped.count == 0)
    XCTAssert(callCount == 0)
    
    array.append(1)
    XCTAssert(callCount == 1)
    
    XCTAssert(mapped[0].value == 1)
    XCTAssert(callCount == 1)
    
    array.insert(2, atIndex: 0)
    XCTAssert(callCount == 2)
    
    XCTAssert(mapped[1].value == 1)
    XCTAssert(callCount == 2)
    
    XCTAssert(mapped[0].value == 2)
    XCTAssert(callCount == 2)
    
    array.removeAtIndex(0)
    XCTAssert(callCount == 2)
    
    XCTAssert(mapped[0].value == 1)
    XCTAssert(callCount == 2)
  }
  
  func testFilterMapChain() {
    let array = ObservableArray<Int>([1, 10])
    
    let mapped = array
      .filter { e in e > 2 }
      .map { e in e * 2 }
      .crystallize()
    
    XCTAssert(mapped.array == [20])
    
    array.removeAll() // []
    XCTAssert(mapped.count == 0)
    
    array.append(1) // 1
    XCTAssert(mapped.array == [])
    
    array.insert(3, atIndex: 0) // 3, 1
    XCTAssert(mapped.array == [6])
    
    array.insertContentsOf([1, 4], atIndex: 1) // 3, 1, 4, 1
    XCTAssert(mapped.array == [6, 8])
    
    array.removeLast() // 3, 1, 4
    XCTAssert(mapped.array == [6, 8])
    
    array.removeAtIndex(2) // 3, 1
    XCTAssert(mapped.array == [6])
    
    array.performBatchUpdates { array in
      array.append(2) // 3, 1, 2
      array.insertContentsOf([1, 5], atIndex: 0) // 1, 5, 3, 1, 2
      array[4] = 4 // 1, 5, 3, 1, 4
    }
    XCTAssert(mapped.array == [10, 6, 8])
  }
  
  func testCrystallize1D() {
    let transform = { $0 * 2 }
    let array = ObservableArray([1, 2])
    
    let mappedObservableArray = array
      .map(transform)
      .crystallize()
    
    XCTAssert(mappedObservableArray.array == array.array.map(transform))
    
    array.append(3)
    XCTAssert(mappedObservableArray.array == array.array.map(transform))
    
    array.removeAll()
    XCTAssert(mappedObservableArray.array == array.array.map(transform))
  }
  
  func testCrystallize2D() {
    let transform = { $0 * 2 }
    let array = ObservableArray([ObservableArray([1, 2]), ObservableArray([10, 20])])
    
    let mappedObservableArray = array
      .map { array in
        return array.map(transform).crystallize()
      }
      .crystallize()
    
    XCTAssert(mappedObservableArray.count == array.count)
    XCTAssert(mappedObservableArray[0].array == array[0].array.map(transform))
    XCTAssert(mappedObservableArray[1].array == array[1].array.map(transform))
    
    array[0].append(3)
    XCTAssert(mappedObservableArray[0].array == array[0].array.map(transform))
    
    array.append(ObservableArray([100]))
    XCTAssert(mappedObservableArray.count == array.count)
    XCTAssert(mappedObservableArray[2].array == array[2].array.map(transform))
  }
  
  func testFilteredObservableArrayAlwaysReplayes() {
    let array = ObservableArray<Int>([1, 2, 3])
    array.insert(7, atIndex: 0) // 7, 1, 2, 3
    XCTAssert(array.count == 4)
    
    let filtered = array.filter { e in e % 2 == 0 }.crystallize()
    XCTAssert(filtered.array == [2])
  }
}
