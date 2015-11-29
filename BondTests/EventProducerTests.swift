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
    
    var eventProducer: EventProducer<Int>! = EventProducer<Int> { sink in
      return simpleDisposable
    }
    
    XCTAssert(eventProducer != nil)
    XCTAssert(simpleDisposable.isDisposed == false, "Initial state.")
    
    eventProducer = nil
    XCTAssert(simpleDisposable.isDisposed == true, "Should be disposed when eventProducer is gone.")
  }
  
  func testDeallocationDisposesObserversDisposables() {
    var eventProducer: EventProducer<Int>! = EventProducer { sink in
      return nil
    }
    
    let observerDisposable1 = eventProducer.observe { v in }
    let observerDisposable2 = eventProducer.observe { v in }
    
    XCTAssert(observerDisposable1.isDisposed == false, "Initial state.")
    XCTAssert(observerDisposable2.isDisposed == false, "Initial state.")
    
    eventProducer = nil
    
    XCTAssert(observerDisposable1.isDisposed == true, "Must be disposed now.")
    XCTAssert(observerDisposable1.isDisposed == true, "Must be disposed now.")
  }
  
  func testObservingAndDisposingObserver() {
    var observedValue = -1
    var capturedSink: (Int -> Void)!
    
    let eventProducer = EventProducer<Int> { sink in
      capturedSink = sink
      return nil
    }
    
    let observerDisposable = eventProducer.observe { v in
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
    var capturedSink: EventProducer<Int>.Sink!
    let cascadingDisposable = SimpleDisposable()
    
    let producer = { (sink: Observable<Int>.Sink) -> DisposableType? in
      capturedSink = sink
      return cascadingDisposable
    }
    
    var eventProducer: EventProducer<Int>! = EventProducer<Int>(replayLength: 0, producer: producer)
    
    // Observer should not cause retention when sink goes away
    eventProducer.observe { v in }
    
    XCTAssert(capturedSink != nil, "We should have sink captured now.")
    XCTAssert(eventProducer != nil, "Should be retained by the sink.")
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed yet.")
    
    capturedSink = nil
    
    XCTAssert(eventProducer != nil, "Should be retained by the variable.")
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed yet.")
    
    weak var eventProducerWeak: EventProducer<Int>! = eventProducer
    eventProducer = nil
    
    XCTAssert(eventProducerWeak == nil, "Should be deallocated.")
    XCTAssert(cascadingDisposable.isDisposed == true, "Should be disposed now.")
  }
  
  func testDisposedAfterRemovingAllObserversIfNotStronglyReferenced() {
    var capturedSink: EventProducer<Int>.Sink!
    let cascadingDisposable = SimpleDisposable()
    
    let producer = { (sink: EventProducer<Int>.Sink) -> DisposableType? in
      capturedSink = sink
      return cascadingDisposable
    }
    
    var eventProducer: EventProducer<Int>! = EventProducer<Int>(replayLength: 0, producer: producer)
    
    XCTAssert(capturedSink != nil, "We should have sink captured now.")
    XCTAssert(eventProducer != nil, "Should be retained by the sink.")
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed yet.")
    
    let disposable = eventProducer.observe { v in }
    XCTAssert(eventProducer != nil, "Should still be retained by the sink.")
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed yet.")

    disposable.dispose()
    
    XCTAssert(eventProducer != nil, "Should be retained by the variable.")
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed yet.")
    
    weak var eventProducerWeak: EventProducer<Int>! = eventProducer
    eventProducer = nil
    
    XCTAssert(eventProducerWeak == nil, "Should be deallocated.")
    XCTAssert(cascadingDisposable.isDisposed == true, "Should be disposed now.")
  }
  
  func testNotDisposedAfterRemovingAllObserversIfStronglyReferenced() {
    var capturedSink: EventProducer<Int>.Sink!
    let cascadingDisposable = SimpleDisposable()
    
    let producer = { (sink: EventProducer<Int>.Sink) -> DisposableType? in
      capturedSink = sink
      return cascadingDisposable
    }
    
    let eventProducer: EventProducer<Int> = EventProducer<Int>(replayLength: 0, producer: producer)
    
    XCTAssert(capturedSink != nil, "We should have sink captured now.")
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed.")
    
    let disposable = eventProducer.observe { v in }
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed.")
    
    disposable.dispose()
    XCTAssert(cascadingDisposable.isDisposed == false, "Should not be disposed.")
  }
  
  func testNormalLifecycleDoesNotCauseSinkToRetainObservableWhenThereIsAnObserver() {
    var capturedSink: (Int -> Void)!
    var eventProducer: EventProducer<Int>! = EventProducer(lifecycle: .Normal) { sink in
      capturedSink = sink
      return nil
    }
    
    let observerDisposable = eventProducer.observe { v in }
    
    XCTAssert(capturedSink != nil, "Initial state.")
    XCTAssert(observerDisposable.isDisposed == false, "Initial state.")

    eventProducer = nil
    XCTAssert(observerDisposable.isDisposed == true, "Must be disposed now.")
  }
  
  func testReplaysCorrectly() {
    let sentValues: [Int] = [1, 2, 3]
    var receivedValues: [Int] = []

    let eventProducer = EventProducer<Int>(replayLength: sentValues.count) { sink in
      for value in sentValues {
        sink(value)
      }
      return nil
    }
    
    eventProducer.observe { v in
      receivedValues += [v]
    }
    
    XCTAssert(sentValues == receivedValues, "Initial state.")
  }
}
