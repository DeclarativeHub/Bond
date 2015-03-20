//
//  AssertEqualsForOptionals.swift
//  Bond
//
//  Created by Anthony Egerton on 15/03/2015.
//  Copyright (c) 2015 Bond. All rights reserved.
//

import Foundation
import XCTest

func XCTAssertEqual<T:Equatable>(actual: T?, expected: T?, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
  switch (actual, expected) {
  case (nil, nil): break
  case (nil, _): XCTFail("(\"nil\") is not equal to (\"\(expected)\")", file: file, line: line)
  case (_, nil): XCTFail("(\"\(actual)\") is not equal to (\"nil\")", file: file, line: line)
  default: XCTAssertEqual(actual!, expected!, message, file: file, line: line)
  }
}

