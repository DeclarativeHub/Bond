//
//  EventProducerTypeTests.swift
//  Bond
//
//  Created by yanamura3 on 04/17/16.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import Bond

class EventProducerTypeTests: XCTestCase {

  func testStartWith() {
    var observedResults = [Int]()

    let sourceObservable = Observable<Int>(1)
    sourceObservable.startWith(0).observe {
      observedResults.append($0)
    }
    XCTAssertEqual(observedResults, [0, 1])

    sourceObservable.value = 2
    XCTAssertEqual(observedResults, [0, 1, 2])

    sourceObservable.value = 3
    XCTAssertEqual(observedResults, [0, 1, 2, 3])
  }
}
