//
//  Helpers.swift
//  Bond
//
//  Created by Srdan Rasic on 29/08/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

@testable import Bond
import ReactiveKit
import XCTest

func XCTAssertEqual(_ lhs: CGFloat, _ rhs: CGFloat, precision: CGFloat = 0.01, file: StaticString = #file, line: UInt = #line) {
    XCTAssert(abs(lhs - rhs) < precision, file: file, line: line)
}

extension Signal.Event {
    func isEqualTo(_ event: Signal<Element, Error>.Event) -> Bool {
        switch (self, event) {
        case (.completed, .completed):
            return true
        case (.failed, .failed):
            return true
        case let (.next(left), .next(right)):
            if let left = left as? Int, let right = right as? Int {
                return left == right
            } else if let left = left as? Bool, let right = right as? Bool {
                return left == right
            } else if let left = left as? Float, let right = right as? Float {
                return left == right
            } else if let left = left as? [Int], let right = right as? [Int] {
                return left == right
            } else if let left = left as? (Int?, Int), let right = right as? (Int?, Int) {
                return left.0 == right.0 && left.1 == right.1
            } else if let left = left as? String, let right = right as? String {
                return left == right
            } else if let left = left as? Date, let right = right as? Date {
                return left == right
            } else if let left = left as? IndexPath, let right = right as? IndexPath {
                return left == right
            } else if let left = left as? [String], let right = right as? [String] {
                return left == right
            } else if let left = asOptional(left) as? String?, let right = asOptional(right) as? String? {
                return left == right
            } else if left is Void, right is Void {
                return true
            } else {
                fatalError("Cannot compare that element type. \(left)")
            }
        default:
            return false
        }
    }
}

private func asOptional(_ object: Any) -> Any? {
    let mirror = Mirror(reflecting: object)
    if mirror.displayStyle != .optional {
        return object
    } else if mirror.children.count == 0 {
        return nil
    } else {
        return mirror.children.first!.value
    }
}

extension SignalProtocol {
    func expectNext(_ expectedElements: [Element],
                    _ message: @autoclosure () -> String = "",
                    expectation: XCTestExpectation? = nil,
                    file: StaticString = #file, line: UInt = #line) {
        expect(expectedElements.map { .next($0) } + [.completed], message(), expectation: expectation, file: file, line: line)
    }

    func expect(_ expectedEvents: [Signal<Element, Error>.Event],
                _ message: @autoclosure () -> String = "",
                expectation: XCTestExpectation? = nil,
                file: StaticString = #file, line: UInt = #line) {
        var eventsToProcess = expectedEvents
        var receivedEvents: [Signal<Element, Error>.Event] = []
        let message = message()
        _ = observe { event in
            receivedEvents.append(event)
            if eventsToProcess.count == 0 {
                XCTFail("Got more events then expected.")
                return
            }
            let expected = eventsToProcess.removeFirst()
            XCTAssert(event.isEqualTo(expected), message + "(Got \(receivedEvents) instead of \(expectedEvents))", file: file, line: line)
            if event.isTerminal {
                expectation?.fulfill()
            }
        }
    }
}
