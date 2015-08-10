//
//  PromiseTests.swift
//  Bond
//
//  Created by Srđan Rašić on 08/08/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import Bond

class PromiseTests: XCTestCase {
  
  func testCancelling() {
    let promise: Promise<Int, NoError> = Promise()
    
    let disposable = promise.onSuccess { value in
    }
    
    XCTAssertFalse(promise.isCanceled)
    
    disposable.dispose()
    XCTAssertTrue(promise.isCanceled)
  }
}