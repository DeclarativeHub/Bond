//
//  ObservableTests.swift
//  Bond
//
//  Created by Srđan Rašić on 01/08/15.
//  Copyright © 2015 Srdan Rasic. All rights reserved.
//

import XCTest
@testable import Bond

class ObservableTests: XCTestCase {
  
  func testDeallocationTriggersCascadingDisposable() {
    let simpleDisposable = SimpleDisposable()
    
    var observable: Observable<Int>! = Observable<Int> { sink in
      return simpleDisposable
    }
    
    XCTAssert(observable != nil)
    XCTAssert(simpleDisposable.isDisposed == false, "Initial state.")
    
    observable = nil
    XCTAssert(simpleDisposable.isDisposed == true, "Should be disposed when observable is gone.")
  }
  
  func testObservingAndDisposingObserver() {
    var observedValue = -1
    
    var capturedSink: (Int -> ())!
    let observable = Observable<Int> { sink in
      capturedSink = sink
      return nil
    }
    
    let observerDisposable = observable.observe { v in
      observedValue = v
    }
    
    XCTAssert(observedValue == -1, "Initial state.")
    XCTAssert(observerDisposable.isDisposed == false, "Initial state.")
    
    capturedSink(0)
    XCTAssert(observedValue == 0, "Should be updated.")
    XCTAssert(observerDisposable.isDisposed == false, "Must not be disposed yet.")
    
    observerDisposable.dispose()
    capturedSink(1)
    XCTAssert(observerDisposable.isDisposed == true, "Should be disposed now.")
    XCTAssert(observedValue == 0, "Should not be updated after disposing.")
  }
  
  func testDisposableByDisposingSink() {
    var capturedSink: Observable<Int>.SinkType!
    let cascadingDisposable = SimpleDisposable()
    
    let producer = { (sink: Observable<Int>.SinkType) -> DisposableType? in
      capturedSink = sink
      return cascadingDisposable
    }
    
    var observable: Observable<Int>! = Observable<Int>(replayLength: 0, producer: producer)
    
    // Observer should not cause retention when sink goes away
    observable.observe { v in }
    
    XCTAssert(capturedSink != nil, "We should have sink captured now.")
    XCTAssert(observable != nil, "Should be retained by the sink.")
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed yet.")
    
    capturedSink = nil
    
    XCTAssert(observable != nil, "Should be retained by the variable.")
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed yet.")
    
    weak var observableWeak: Observable<Int>! = observable
    observable = nil
    
    XCTAssert(observableWeak == nil, "Should be deallocated.")
    XCTAssert(cascadingDisposable.isDisposed == true, "Should be disposed now.")
  }
  
  func testDisposedAfterRemovingAllObserversIfNotStronglyReferenced() {
    var capturedSink: Observable<Int>.SinkType!
    let cascadingDisposable = SimpleDisposable()
    
    let producer = { (sink: Observable<Int>.SinkType) -> DisposableType? in
      capturedSink = sink
      return cascadingDisposable
    }
    
    var observable: Observable<Int>! = Observable<Int>(replayLength: 0, producer: producer)
    
    XCTAssert(capturedSink != nil, "We should have sink captured now.")
    XCTAssert(observable != nil, "Should be retained by the sink.")
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed yet.")
    
    let disposable = observable.observe { v in }
    XCTAssert(observable != nil, "Should still be retained by the sink.")
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed yet.")

    disposable.dispose()
    
    XCTAssert(observable != nil, "Should be retained by the variable.")
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed yet.")
    
    weak var observableWeak: Observable<Int>! = observable
    observable = nil
    
    XCTAssert(observableWeak == nil, "Should be deallocated.")
    XCTAssert(cascadingDisposable.isDisposed == true, "Should be disposed now.")
  }
  
  func testNotDisposedAfterRemovingAllObserversIfStronglyReferenced() {
    var capturedSink: Observable<Int>.SinkType!
    let cascadingDisposable = SimpleDisposable()
    
    let producer = { (sink: Observable<Int>.SinkType) -> DisposableType? in
      capturedSink = sink
      return cascadingDisposable
    }
    
    let observable: Observable<Int> = Observable<Int>(replayLength: 0, producer: producer)
    
    XCTAssert(capturedSink != nil, "We should have sink captured now.")
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed.")
    
    let disposable = observable.observe { v in }
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed.")
    
    disposable.dispose()
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed.")
  }
  
  func testReplaysCorrectly() {
    let sentValues: [Int] = [1, 2, 3]
    var receivedValues: [Int] = []

    let observable = Observable<Int>(replayLength: sentValues.count) { sink in
      for value in sentValues {
        sink(value)
      }
      return nil
    }
    
    observable.observe { v in
      receivedValues += [v]
    }
    
    XCTAssert(sentValues == receivedValues, "Initial state.")
  }
}
