//
//  Helpers.swift
//  Bond
//
//  Created by Srdan Rasic on 29/08/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import XCTest
@testable import ReactiveKit
@testable import Bond

func XCTAssertEqual(_ lhs: CGFloat, _ rhs: CGFloat, precision: CGFloat = 0.01, file: StaticString = #file, line: UInt = #line) {
    XCTAssert(abs(lhs - rhs) < precision, file: file, line: line)
}
extension Event {

    func isEqualTo(_ event: Event<Element, Error>) -> Bool {

        switch (self, event) {
        case (.completed, .completed):
            return true
        case (.failed, .failed):
            return true
        case (.next(let left), .next(let right)):
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
            } else if let left = asOptional(left) as? Optional<String>, let right = asOptional(right) as? Optional<String> {
                return left == right
            } else if let left = left as? ObservableArrayEvent<Int>, let right = right as? ObservableArrayEvent<Int> {
                return left.change == right.change && (left.source === right.source || right.source === AnyObservableArray)
            } else if let left = left as? Observable2DArrayEvent<String, Int>, let right = right as? Observable2DArrayEvent<String, Int> {
                return left.change == right.change && (left.source === right.source || right.source === AnyObservable2DArray)
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
        expect(expectedElements.map { .next($0) } + [.completed], message, expectation: expectation, file: file, line: line)
    }

    func expect(_ expectedEvents: [Event<Element, Error>],
                _ message: @autoclosure () -> String = "",
                expectation: XCTestExpectation? = nil,
                file: StaticString = #file, line: UInt = #line) {
        var eventsToProcess = expectedEvents
        var receivedEvents: [Event<Element, Error>] = []
        let message = message()
        let _ = observe { event in
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

let AnyObservableArray = ObservableArray<Int>()
let AnyObservable2DArray = Observable2DArray<String,Int>()

extension Observable2DArrayChange: Equatable {

    public static func ==(lhs: Observable2DArrayChange, rhs: Observable2DArrayChange) -> Bool {
        switch (lhs, rhs) {
        case (.reset, .reset):
            return true
        case (.insertItems(let lhs), .insertItems(let rhs)):
            return lhs == rhs
        case (.deleteItems(let lhs), .deleteItems(let rhs)):
            return lhs == rhs
        case (.updateItems(let lhs), .updateItems(let rhs)):
            return lhs == rhs
        case (.moveItem(let lhsFrom, let lhsTo), .moveItem(let rhsFrom, let rhsTo)):
            return lhsFrom == rhsFrom && lhsTo == rhsTo
        case (.insertSections(let lhs), .insertSections(let rhs)):
            return lhs == rhs
        case (.deleteSections(let lhs), .deleteSections(let rhs)):
            return lhs == rhs
        case (.updateSections(let lhs), .updateSections(let rhs)):
            return lhs == rhs
        case (.moveSection(let lhsFrom, let lhsTo), .moveSection(let rhsFrom, let rhsTo)):
            return lhsFrom == rhsFrom && lhsTo == rhsTo
        case (.beginBatchEditing, .beginBatchEditing):
            return true
        case (.endBatchEditing, .endBatchEditing):
            return true
        default:
            return false
        }
    }
}

extension DataSourceEventKind: Equatable {

    public static func ==(lhs: DataSourceEventKind, rhs: DataSourceEventKind) -> Bool {
        switch (lhs, rhs) {
        case (.reload, .reload):
            return true
        case (.insertItems(let lhs), .insertItems(let rhs)):
            return lhs == rhs
        case (.deleteItems(let lhs), .deleteItems(let rhs)):
            return lhs == rhs
        case (.reloadItems(let lhs), .reloadItems(let rhs)):
            return lhs == rhs
        case (.moveItem(let lhsFrom, let lhsTo), .moveItem(let rhsFrom, let rhsTo)):
            return lhsFrom == rhsFrom && lhsTo == rhsTo
        case (.insertSections(let lhs), .insertSections(let rhs)):
            return lhs == rhs
        case (.deleteSections(let lhs), .deleteSections(let rhs)):
            return lhs == rhs
        case (.reloadSections(let lhs), .reloadSections(let rhs)):
            return lhs == rhs
        case (.moveSection(let lhsFrom, let lhsTo), .moveSection(let rhsFrom, let rhsTo)):
            return lhsFrom == rhsFrom && lhsTo == rhsTo
        case (.beginUpdates, .beginUpdates):
            return true
        case (.endUpdates, .endUpdates):
            return true
        default:
            return false
        }
    }
}
