//
//  Observable2DArrayTests.swift
//  Bond
//
//  Created by MOHAMMAD TAWEEL on 1/11/17.
//  Copyright © 2017 Swift Bond. All rights reserved.
//

import Foundation

import XCTest
@testable import Bond

class Observable2DArrayTests: XCTestCase {

    var array2D: MutableObservable2DArray<String,Int>!

    override func setUp() {
        super.setUp()
        array2D = MutableObservable2DArray([
            Observable2DArraySection(metadata: "units", items: [1,2,3]),
            Observable2DArraySection(metadata: "tens", items: [10,20,30]),
            Observable2DArraySection(metadata: "hundreds", items: [100,200,300]),
            Observable2DArraySection(metadata: "thousands", items: [1000,2000,3000]),
            ])
    }

    func testReplace2D() {

        let newArray = Observable2DArray([
            Observable2DArraySection(metadata: "tens", items: [10,30]),
            Observable2DArraySection(metadata: "hundreds", items: [100,200,400]),
            Observable2DArraySection(metadata: "millions", items: [1000000,2000000,3000000]),
            Observable2DArraySection(metadata: "units", items: [4,3,2]),
            ])

        array2D.expectNext([
            Observable2DArrayEvent<String, Int>(change: .reset, source: array2D),
            Observable2DArrayEvent<String, Int>(change: .beginBatchEditing, source: array2D),
            Observable2DArrayEvent<String, Int>(change: .deleteItems([IndexPath(item:0, section:0), IndexPath(item:1, section:1), IndexPath(item:2, section:2)]), source: array2D),
            Observable2DArrayEvent<String, Int>(change: .insertItems([IndexPath(item:0, section:3), IndexPath(item:2, section:1)]), source: array2D),
            Observable2DArrayEvent<String, Int>(change: .moveItem(IndexPath(item:1, section:0), IndexPath(item:2, section:3)), source: array2D),
            Observable2DArrayEvent<String, Int>(change: .deleteSections(IndexSet([3])), source: array2D),
            Observable2DArrayEvent<String, Int>(change: .insertSections(IndexSet([2])), source: array2D),
            Observable2DArrayEvent<String, Int>(change: .moveSection(0,3), source: array2D),
            Observable2DArrayEvent<String, Int>(change: .endBatchEditing, source: array2D)
            ])

        array2D.replace(with: newArray, performDiff: true)
    }

}
