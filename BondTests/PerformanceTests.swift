//
//  PerformanceTests.swift
//  Bond
//
//  Created by Ivan Moskalev on 19.06.15.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import XCTest
import Bond

class BondPerformanceTests: XCTestCase {

  func testBindPerformance() {
    let dynamicInt = Dynamic<Int>(0)
    let intBond = Bond<Int>({ value in })

    self.measureBlock {
      dynamicInt.bindTo(intBond)
    }
  }

  func testUnbindAllPerformance() {
    self.measureMetrics(self.dynamicType.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) { () -> Void in

      // Setup
      let dynamics = Array(count: 100, repeatedValue: Dynamic<Int>(0))
      let intBond = Bond<Int>({ value in })

      for dynamic in dynamics {
        dynamic ->| intBond
      }

      // Test
      self.startMeasuring()
      intBond.unbindAll()
      self.stopMeasuring()

    }
  }

}


class DynamicPerformanceTests: XCTestCase {

  func testDispatchPerformance() {
    self.measureMetrics(self.dynamicType.defaultPerformanceMetrics(), automaticallyStartMeasuring: false) { () -> Void in

      // Setup
      let dynamicInt = Dynamic<Int>(0)
      let intBond = Bond<Int>({ value in })

      dynamicInt.bindTo(intBond)

      // Test
      self.startMeasuring()
      dynamicInt.value = 1
      self.stopMeasuring()

    }
  }

}
