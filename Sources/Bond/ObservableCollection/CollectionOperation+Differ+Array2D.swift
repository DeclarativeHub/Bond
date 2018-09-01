//
//  The MIT License (MIT)
//
//  Copyright (c) 2018 DeclarativeHub/Bond
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Differ
import Foundation
import ReactiveKit

extension MutableObservableCollection
where UnderlyingCollection: Array2DProtocol {

    public func replaceSection(at index: Int, newItems: [Item], performDiff: Bool, areEqual: @escaping (Item, Item) -> Bool) {
        if performDiff {
            descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
                let section = collection.array2DView.sections[index]
                let diff = section.items.extendedDiff(newItems, isEqual: areEqual).diff.map { $0.mapIndex { IndexPath(item: $0, section: index) } }
                collection.array2DView.sections[index].items = newItems
                return diff
            }
        } else {
            descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
                collection.array2DView.sections[index].items = newItems
                return []
            }
        }
    }
}

extension MutableObservableCollection
where UnderlyingCollection: Array2DProtocol, UnderlyingCollection.Item: Equatable {

    public func replaceSection(at index: Int, newItems: [Item], performDiff: Bool) {
        return replaceSection(at: index, newItems: newItems, performDiff: performDiff, areEqual: { $0 == $1 })
    }
}
