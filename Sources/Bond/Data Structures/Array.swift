//
//  Array.swift
//  Bond-iOS
//
//  Created by Srdan Rasic on 28/09/2018.
//  Copyright © 2018 Swift Bond. All rights reserved.
//

import Foundation

extension Array {

    func insertionIndex(of element: Element, isOrderedBefore: (Element, Element) -> Bool) -> Int {
        var lo = 0
        var hi = self.count - 1
        while lo <= hi {
            let mid = (lo + hi)/2
            if isOrderedBefore(self[mid], element) {
                lo = mid + 1
            } else if isOrderedBefore(element, self[mid]) {
                hi = mid - 1
            } else {
                return mid
            }
        }
        return lo
    }

    mutating func insert(_ element: Element, isOrderedBefore: (Element, Element) -> Bool) {
        let index = insertionIndex(of: element, isOrderedBefore: isOrderedBefore)
        insert(element, at: index)
    }
}
