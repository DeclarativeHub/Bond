//
//  MutableObservableTests.swift
//  Bond
//
//  Created by Srdan Rasic on 18/11/15.
//  Copyright © 2015 Bond. All rights reserved.
//

import XCTest
@testable import Bond

class MutableObservableTests: XCTestCase {

  func testObservingAndDisposing() {
    var age = MutableObservable(2)

    age.value = 1
    age.value = 0

    var observedValue = -1
    var numberOfInitialReplays = 0

    let disposable = age.observe { value in
      observedValue = value
      numberOfInitialReplays += 1
    }

    XCTAssertEqual(1, numberOfInitialReplays)
    XCTAssertEqual(0, observedValue)

    age.value = 1
    XCTAssertEqual(1, observedValue)

    age.value = 2
    XCTAssertEqual(2, observedValue)

    disposable.dispose()

    age.value = 3
    XCTAssertEqual(2, observedValue)
  }
}
