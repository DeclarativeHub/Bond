//
//  ObservableSetTests.swift
//  Bond
//
//  Created by Ahmed Afifi on 19/09/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import XCTest
@testable import Bond

class ObservableSetTests: XCTestCase {
    
    var set: MutableObservableSet<IntBox>!
    
    struct IntBox: Hashable {
        let identifier: Int
        let contents: String
        
        var hashValue: Int {
            return identifier.hashValue
        }
        
        static func ==(lhs: IntBox, rhs: IntBox) -> Bool {
            return lhs.identifier == rhs.identifier
        }
    }
    
    override func setUp() {
        super.setUp()
        let itemOne = IntBox(identifier: 1, contents: "Item One")
        let itemTwo = IntBox(identifier: 2, contents: "Item Two")
        let itemThree = IntBox(identifier: 3, contents: "Item Three")
        
        set = MutableObservableSet([itemOne, itemTwo, itemThree])
    }
    
    func testRemoveAll() {
        set.removeAll()
        XCTAssert(set.isEmpty)
    }
    
    func testInsertOfExistingItem() {
        let updatedItemOne = IntBox(identifier: 1, contents: "New Item One")
        
        // Expect no updates due to already existing element
        
        set.insert(updatedItemOne)
        
        let index = set.index(of: updatedItemOne)!
        XCTAssert(set[index] == updatedItemOne)
        XCTAssert(set[index].contents == "Item One")
    }
    
    func testInsertNewItem() {
        let newItem = IntBox(identifier: 4, contents: "Item Four")
        
        set.insert(newItem)
        
        let index = set.index(of: newItem)!
        XCTAssert(set[index] == newItem)
        XCTAssert(set[index].contents == "Item Four")
    }
    
    func testUpdateExistingItem() {
        let updatedItemOne = IntBox(identifier: 1, contents: "New Item One")
        
        set.update(updatedItemOne)
        
        let index = set.index(of: updatedItemOne)!
        XCTAssert(set[index] == updatedItemOne)
        XCTAssert(set[index].contents == "New Item One")
    }
    
    func testUpdateNewItem() {
        let newItem = IntBox(identifier: 4, contents: "Item Four")
        
        set.update(newItem)
        
        let index = set.index(of: newItem)!
        XCTAssert(set[index] == newItem)
        XCTAssert(set[index].contents == "Item Four")
    }
}
