//
//  ObservableTests.swift
//  Bond
//
//  Created by Srđan Rašić on 22/07/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import Bond

class ObservableValueTests: XCTestCase {

  func testObservingAndDisposing() {
    let age = Observable(2)
    
    age.next(1)
    age.next(0)
    
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
    
    age.next(2)
    XCTAssertEqual(2, observedValue)
    
    disposable.dispose()
    
    age.value = 3
    XCTAssertEqual(2, observedValue)
  }
  
  func testFilterMapChain() {
    let observable = Observable(2)
    var observedValue = -1
    
    observable
      .filter { $0 % 2 == 0 }
      .map { $0 * 2 }
      .observe { value in
        observedValue = value
      }
    
    XCTAssertEqual(observedValue, 4)
    
    observable.value = 3
    XCTAssertEqual(observedValue, 4)

    observable.value = 4
    XCTAssertEqual(observedValue, 8)
  }
  
  func testDisposesOnReleasingEvenThoughBeingObserved() {
    var observable: Observable<Int>! = Observable(0)
    weak var observableWeak: Observable<Int>! = observable
    
    let disposable = observable.observe { v in }
    
    XCTAssertNotNil(observableWeak)
    XCTAssertFalse(disposable.isDisposed)
    
    observable = nil
    XCTAssertNil(observableWeak)
    XCTAssertTrue(disposable.isDisposed)
  }
  
  func testDisposesOnReleasingEvenThoughBeingBound() {
    let srcObservable: Observable<Int> = Observable(0)
    
    var dstObservable: Observable<Int>! = Observable(0)
    weak var dstObservableWeak: Observable<Int>! = dstObservable
    
    let disposable = srcObservable.bindTo(dstObservable)
    
    XCTAssertNotNil(dstObservableWeak)
    XCTAssertFalse(disposable.isDisposed)
    
    dstObservable = nil
    XCTAssertNil(dstObservableWeak)
    XCTAssertTrue(disposable.isDisposed)
  }
  
  func testNotRetainedByCreatedSinkAndDisposesGivenDisposableOnDeinit() {
    var observable: Observable<Int>! = Observable(0)
    weak var observableWeak: Observable<Int>! = observable
    let disposable = SimpleDisposable()
    
    let sink: (Int -> Void)? = observable.sink(disposable)
    
    XCTAssert(sink != nil)
    XCTAssertNotNil(observableWeak)
    XCTAssertFalse(disposable.isDisposed)
    
    observable = nil
    XCTAssertNil(observableWeak)
    XCTAssertTrue(disposable.isDisposed)
  }
}
