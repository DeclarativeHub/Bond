//
//  DiffTests.swift
//  Bond
//
//  Created by Dapeng Gao on 20/10/15.
//  Copyright © 2015 Bond. All rights reserved.
//

// This test case is taken from https://github.com/jflinter/Dwifft

import XCTest
@testable import Bond

class DiffTests: XCTestCase {
  
  struct TestCase {
    let array1: [Character]
    let array2: [Character]
    let expectedDiff: String
    init(_ a: String, _ b: String, _ expectedDiff: String) {
      self.array1 = Array(a.characters)
      self.array2 = Array(b.characters)
      self.expectedDiff = expectedDiff
    }
  }
  
  private func encodeDiff<T>(x: [DiffStep<T>]) -> String {
    var result = ""
    for step in x {
      switch step {
      case let .Insert(e, i): result += "+\(e)@\(i)"
      case let .Delete(e, i): result += "-\(e)@\(i)"
      }
    }
    return result
  }
  
  func testDiff() {
    let tests: [TestCase] = [
      TestCase("1234", "23", "-1@0-4@3"),
      TestCase("0125890", "4598310", "-0@0-1@1-2@2+4@0-8@4+8@3+3@4+1@5"),
      TestCase("BANANA", "KATANA", "-B@0+K@0-N@2+T@2"),
      TestCase("1234", "1224533324", "+2@2+4@3+5@4+3@6+3@7+2@8"),
      TestCase("thisisatest", "testing123testing", "-h@1-i@2+e@1+t@3-s@5-a@6+n@5+g@6+1@7+2@8+3@9+i@14+n@15+g@16"),
      TestCase("HUMAN", "CHIMPANZEE", "+C@0-U@1+I@2+P@4+Z@7+E@8+E@9"),
    ]
    
    for test in tests {
      
      let diff = Array.diff(test.array1, test.array2)
      let stringRepresentation = encodeDiff(diff)
      
      XCTAssertEqual(stringRepresentation, test.expectedDiff)
    }
  }
}
