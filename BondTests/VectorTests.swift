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
