//
//  SimpleDiffTests.swift
//  Bond
//
//  Created by Ivan Moskalev on 19/11/15.
//  Copyright © 2015 Bond. All rights reserved.
//

import XCTest
@testable import Bond

class SimpleDiffTests: XCTestCase {

  func testAllSame() {
    let first  = [1, 2, 3]
    let second = [1, 2, 3]

    let operations = simpleDiff(first, after: second)
    XCTAssert(operations.count == 1, "Only one operation should be present!")
    XCTAssert(operations.first! == .Noop(elements: [1, 2, 3]), "Operation should be `Noop`!")
  }

  func testDeleted() {
    let first  = [1, 2, 3]
    let second = [1, 3]

    let operations = simpleDiff(first, after: second)
    XCTAssert(operations.count == 3, "Three operations should be present!")
    XCTAssert(operations[0] == .Noop(elements: [1]))
    XCTAssert(operations[1] == .Delete(elements: [2]))
    XCTAssert(operations[2] == .Noop(elements: [3]))
  }

  func testInserted() {
    let first  = [1, 2, 3]
    let second = [1, 2, 0, 3]

    let operations = simpleDiff(first, after: second)
    XCTAssert(operations.count == 3, "Three operations should be present!")
    XCTAssert(operations[0] == .Noop(elements: [1, 2]))
    XCTAssert(operations[1] == .Insert(elements: [0]))
    XCTAssert(operations[2] == .Noop(elements: [3]))
  }

  func testAllChanged() {
    let first  = [1, 2, 3]
    let second = [4, 5, 6]

    let operations = simpleDiff(first, after: second)
    XCTAssert(operations.count == 2, "Two operations should be present!")
    XCTAssert(operations[0] == .Delete(elements: [1, 2, 3]))
    XCTAssert(operations[1] == .Insert(elements: [4, 5, 6]))
  }


}

private func ==<T: Equatable>(a: SimpleDiffOperation<T>, b: SimpleDiffOperation<T>) -> Bool {
  switch (a, b) {
  case (.Noop(let a), .Noop(let b))     where a == b: return true
  case (.Delete(let a), .Delete(let b)) where a == b: return true
  case (.Insert(let a), .Insert(let b)) where a == b: return true
  default: return false
  }
}
