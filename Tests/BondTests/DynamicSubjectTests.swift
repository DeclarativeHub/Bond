//
//  DynamicSubjectTests.swift
//  Bond
//
//  Created by Srdan Rasic on 22/09/2016.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import XCTest
import ReactiveKit
@testable import Bond

private class DummyTarget: NSObject {
    var value: Int = 5
    var recordedElements: [Int] = []
    let changes = PublishSubject1<Void>()
}

class DynamicSubjectTests: XCTestCase {

    // Starts with current value
    // Update signal triggers next event
    // Bound signal events are propagated
    // Value property is being updated (set closure is called)
    func testExecutes() {
        let target = DummyTarget()
        let subject = DynamicSubject(
            target: target,
            signal: target.changes.toSignal(),
            context: .immediate,
            get: { (target) -> Int in target.value },
            set: { (target, new) in target.value = new; target.recordedElements.append(new) }
        )

        subject.expectNext([5, 6, 7, 1, 2, 3])
        target.value = 6
        target.changes.next(())
        XCTAssert(target.value == 6)

        subject.on(.next(7))
        XCTAssert(target.value == 7)

        SafeSignal.sequence([1, 2, 3]).bind(to: subject)
        XCTAssert(target.recordedElements == [7, 1, 2, 3])
        XCTAssert(target.value == 3)
    }

    // Target is weakly referenced
    // Disposable is disposed when target is deallocated
    // Completed event is sent when target is deallocated
    func testDisposesOnTargetDeallocation() {
        var target: DummyTarget! = DummyTarget()
        weak var weakTarget = target
        
        let subject = DynamicSubject(
            target: target,
            signal: target.changes.toSignal(),
            context: .immediate,
            get: { (target) -> Int in target.value },
            set: { (target, new) in target.value = new; target.recordedElements.append(new) }
        )

        let signal = PublishSubject1<Int>()
        let disposable = signal.bind(to: subject)

        subject.expect([.next(5), .next(1), .completed], expectation: expectation(description: "completed"))

        signal.next(1)
        XCTAssert(weakTarget != nil)
        XCTAssert(disposable.isDisposed == false)
        XCTAssert(target.recordedElements == [1])

        target = nil
        signal.next(2)
        XCTAssert(weakTarget == nil)
        XCTAssert(disposable.isDisposed == true)

        waitForExpectations(timeout: 1, handler: nil)
    }
}
