//
//  VectorTests.swift
//  Bond
//
//  Created by Srdan Rasic on 31/07/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import Bond

class VectorTests: XCTestCase {
  
  func testVectorOperations() {
    let vector = Vector<Int>([])
    
    XCTAssert(vector.count == 0)
    
    vector.append(1)
    XCTAssert(vector.count == 1)
    XCTAssert(vector[0] == 1)
    
    vector.append(2)
    XCTAssert(vector.count == 2)
    XCTAssert(vector.array == [1, 2])
    
    vector.insert(3, atIndex: 0)
    XCTAssert(vector.count == 3)
    XCTAssert(vector.array == [3, 1, 2])
    
    vector.extend([4, 5])
    XCTAssert(vector.count == 5)
    XCTAssert(vector.array == [3, 1, 2, 4, 5])
    
    let last = vector.removeLast()
    XCTAssert(vector.count == 4)
    XCTAssert(vector.array == [3, 1, 2, 4])
    XCTAssert(last == 5)
    
    let element = vector.removeAtIndex(1)
    XCTAssert(vector.count == 3)
    XCTAssert(vector.array == [3, 2, 4])
    XCTAssert(element == 1)
    
    vector.splice([8, 9], atIndex: 1)
    XCTAssert(vector.count == 5)
    XCTAssert(vector.array == [3, 8, 9, 2, 4])
    
    vector[0] = 0
    XCTAssert(vector.count == 5)
    XCTAssert(vector.array == [0, 8, 9, 2, 4])
    
    vector.removeAll()
    XCTAssert(vector.count == 0)
    XCTAssert(vector.array == [])
  }
  
  func testVectorMap() {
    let vector = Vector<Int>([])
    let mapped = vector.map { e in e * 2 }.crystallize()
    
    XCTAssert(vector.count == 0)
    XCTAssert(mapped.count == 0)
    
    vector.append(1)
    XCTAssert(mapped.count == 1)
    XCTAssert(mapped[0] == 2)
    
    vector.insert(2, atIndex: 0)
    XCTAssert(mapped.count == 2)
    XCTAssert(mapped[0] == 4)
    XCTAssert(mapped[1] == 2)
    
    vector.splice([3, 4], atIndex: 1)
    XCTAssert(mapped.count == 4)
    XCTAssert(mapped[0] == 4)
    XCTAssert(mapped[1] == 6)
    XCTAssert(mapped[2] == 8)
    XCTAssert(mapped[3] == 2)
    
    vector.removeLast()
    XCTAssert(mapped.count == 3)
    XCTAssert(mapped[0] == 4)
    XCTAssert(mapped[1] == 6)
    XCTAssert(mapped[2] == 8)
    
    vector.removeAtIndex(1)
    XCTAssert(mapped.count == 2)
    XCTAssert(mapped[0] == 4)
    XCTAssert(mapped[1] == 8)
    
    vector.removeAll()
    XCTAssert(mapped.count == 0)
  }
  
  func testArrayMapCallCount() {
    class Test {
      var value: Int
      init(_ value: Int) { self.value = value }
    }
    
    var callCount: Int = 0
    let vector = Vector<Int>([])
    
    let mapped = vector
      .map { e -> Test in
        callCount++
        return Test(e)
      }
    
    XCTAssert(callCount == 0)
    
    vector.append(1)
    XCTAssert(callCount == 1)
    
    vector.insert(2, atIndex: 0)
    XCTAssert(callCount == 2)
    
    vector.removeAtIndex(0)
    XCTAssert(callCount == 2)
    
    vector.removeLast()
    XCTAssert(callCount == 2)
    
    vector.splice([1, 2, 3, 4], atIndex: 0)
    XCTAssert(callCount == 6)

    vector.removeAtIndex(1)
    XCTAssert(callCount == 6)
    
    vector.insert(2, atIndex: 1)
    XCTAssert(callCount == 7)
    
    mapped.observe { vectorEvent in
      vectorEvent.sequence.first // just access any element
    }
    
    XCTAssert(callCount == 8)
    
    vector.removeAll()
    XCTAssert(callCount == 8)
  }
  
  func testVectorMapCrystallizeCorrectAndDoesNotAffectCallCount() {
    class Test {
      var value: Int
      init(_ value: Int) { self.value = value }
    }
    
    var callCount: Int = 0
    let vector = Vector<Int>([])
    
    let mapped = vector
      .map { e -> Test in
        callCount++
        return Test(e)
      }
      .crystallize()
    
    XCTAssert(mapped.count == 0)
    XCTAssert(callCount == 0)
    
    vector.append(1)
    XCTAssert(callCount == 1)
    
    XCTAssert(mapped[0].value == 1)
    XCTAssert(callCount == 1)
    
    vector.insert(2, atIndex: 0)
    XCTAssert(callCount == 2)
    
    XCTAssert(mapped[1].value == 1)
    XCTAssert(callCount == 2)
    
    XCTAssert(mapped[0].value == 2)
    XCTAssert(callCount == 2)
    
    vector.removeAtIndex(0)
    XCTAssert(callCount == 2)
    
    XCTAssert(mapped[0].value == 1)
    XCTAssert(callCount == 2)
  }
  
  func testCrystallize1D() {
    let transform = { $0 * 2 }
    let vector = Vector([1, 2])
    let mappedVector = vector.map(transform).crystallize()
    
    XCTAssert(mappedVector.array == vector.array.map(transform))
    
    vector.append(3)
    XCTAssert(mappedVector.array == vector.array.map(transform))
    
    vector.removeAll()
    XCTAssert(mappedVector.array == vector.array.map(transform))
  }
  
  func testCrystallize2D() {
    let transform = { $0 * 2 }
    let vector = Vector([Vector([1, 2]), Vector([10, 20])])
    
    let mappedVector = vector.map { vector in
      return vector.map(transform).crystallize()
    }.crystallize()
    
    XCTAssert(mappedVector.count == vector.count)
    XCTAssert(mappedVector[0].array == vector[0].array.map(transform))
    XCTAssert(mappedVector[1].array == vector[1].array.map(transform))
    
    vector[0].append(3)
    XCTAssert(mappedVector[0].array == vector[0].array.map(transform))
    
    vector.append(Vector([100]))
    XCTAssert(mappedVector.count == vector.count)
    XCTAssert(mappedVector[2].array == vector[2].array.map(transform))
  }
}
