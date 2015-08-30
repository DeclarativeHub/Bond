//
//  ObservableArrayOperationTests.swift
//  Bond
//
//  Created by Srđan Rašić on 06/08/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import Bond

enum Letters {
  case A
  case B
  case C
  case D
}

func ==(lsh: [ObservableArrayEventChangeSet], rhs: [ObservableArrayEventChangeSet]) -> Bool {
  if lsh.count != rhs.count {
    return false
  } else {
    for (l, r) in zip(lsh, rhs) {
      if !(l == r) {
        return false
      }
    }
    return true
  }
}

class ObservableArrayEventTests: XCTestCase {
  
  // Assuming change set has at most three elements in 
  // the following order: .Inserts, .Updates, .Deletes
  
  func testChangeSetInsert() {
    let operations: [ObservableArrayOperation<Letters>] = [
      .Insert(elements: [.A, .B, .C], fromIndex: 1)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.Inserts([1, 2, 3])])
  }
  
  func testChangeSetDelete() {
    let operations: [ObservableArrayOperation<Letters>] = [
      .Remove(range: 1..<4)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.Deletes([1, 2, 3])])
  }
  
  func testChangeSetUpdate() {
    let operations: [ObservableArrayOperation<Letters>] = [
      .Update(elements: [.A, .B, .C], fromIndex: 1)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.Updates([1, 2, 3])])
  }
  
  func testChangeSetInsertDeleteOverlapping() {
    let operations: [ObservableArrayOperation<Letters>] = [
      .Insert(elements: [.A, .B, .C], fromIndex: 1),
      .Remove(range: 1...2)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.Inserts([1])])
  }
  
  func testChangeSetInsertDeleteNonOverlapping1() {
    let operations: [ObservableArrayOperation<Letters>] = [
      .Insert(elements: [.A, .B, .C], fromIndex: 1),
      .Remove(range: 0..<1)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.Inserts([0, 1, 2]), .Deletes([0])])
  }
  
  func testChangeSetInsertDeleteNonOverlapping2() {
    let operations: [ObservableArrayOperation<Letters>] = [
      .Insert(elements: [.A, .B, .C], fromIndex: 1),
      .Remove(range: 5...6)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.Inserts([1, 2, 3]), .Deletes([5, 6])])
  }
  
  func testChangeSetDeleteInsertOverlapping() {
    let operations: [ObservableArrayOperation<Letters>] = [
      .Remove(range: 1...2),
      .Insert(elements: [.A, .B, .C], fromIndex: 1)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.Inserts([3]), .Updates([1, 2])])
  }
  
  func testChangeSetDeleteInsertNonOverlapping1() {
    let operations: [ObservableArrayOperation<Letters>] = [
      .Remove(range: 0...1),
      .Insert(elements: [.A, .B, .C], fromIndex: 2)
    ]
    
    let changeSets = changeSetsFromBatchOperations(operations)
    XCTAssert(changeSets == [.Inserts([2, 3, 4]), .Deletes([0, 1])])
  }
}
