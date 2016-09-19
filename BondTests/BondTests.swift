//
//  BondTests.swift
//  Bond
//
//  Created by Srdan Rasic on 19/09/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import XCTest
import ReactiveKit
@testable import Bond

class DummyTarget: NSObject {
  var recordedElements: [Int] = []
}

class BondTypeTests: XCTestCase {
  
  func testExecutes() {
    let target = DummyTarget()
    let bond = Bond<DummyTarget, Int>(target: target) { target, element in
      target.recordedElements.append(element)
    }
    
    Signal1.sequence([1, 2, 3]).bind(to: bond)
    XCTAssert(target.recordedElements == [1, 2, 3])
  }
  
  func testDisposesOnTargetDeallocation() {
    var target: DummyTarget! = DummyTarget()
    weak var weakTarget = target
    
    let bond = Bond<DummyTarget, Int>(target: target) { target, element in
      target.recordedElements.append(element)
    }
    
    let subject = PublishSubject1<Int>()
    
    let disposable = subject.bind(to: bond)
    
    subject.next(1)
    XCTAssert(weakTarget != nil)
    XCTAssert(disposable.isDisposed == false)
    XCTAssert(target.recordedElements == [1])

    target = nil
    subject.next(2)
    XCTAssert(weakTarget == nil)
    XCTAssert(disposable.isDisposed == true)
  }
}
