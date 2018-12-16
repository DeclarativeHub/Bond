//
//  UIPickerViewTests.swift
//  BondTests
//
//  Created by Jonathan Foster on 2/17/19.
//  Copyright © 2019 Swift Bond. All rights reserved.
//

#if os(iOS) || os(tvOS)

import XCTest
import ReactiveKit
@testable import Bond

class UIPickerViewTests: XCTestCase {

    var array: MutableObservableArray<Int>!
    var pickerView: UIPickerView!

    override func setUp() {
        array = MutableObservableArray([1, 2, 3])
        pickerView = UIPickerView()
    }

    func testBind() {
        array.bind(to: pickerView)
    }

    func testBindUsingCreateTitle() {
        array.bind(to: pickerView) { (dataSource, row, component, pickerView) -> String? in
            let indexPath = IndexPath(row: row, section: component)
            let item = dataSource.item(at: indexPath)

            return String(describing: item)
        }
    }

    func testBindUsingBinderDataSource() {
        let createTitle: ([Int], Int, Int, UIPickerView) -> String? = { (dataSource, row, component, pickerView) in
            let indexPath = IndexPath(row: row, section: component)
            let item = dataSource.item(at: indexPath)

            return String(describing: item)
        }

        array.bind(to: pickerView, using: PickerViewBinderDataSource(createTitle))
    }
}

#endif
