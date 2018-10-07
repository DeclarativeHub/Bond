//
//  The MIT License (MIT)
//
//  Copyright (c) 2016 Srdan Rasic (@srdanrasic)
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

import Foundation

/// Array2D is a 3-level tree of nodes with `Array2DElement<Section, Item>` values.
/// First level represents the root node and contains no value. Second level represents
/// sections and contains `Array2DElement.section` values, while the third level represents
/// items and contains `Array2DElement.item` values.
///
/// Signals that emit this kind of a tree can be bound to a table or collection view.
public typealias Array2D<Section, Item> = TreeArray<Array2DElement<Section, Item>>

extension TreeArray where ChildValue: Array2DElementProtocol {

    public init(sectionsWithItems: [(ChildValue.Section, [ChildValue.Item])]) {
        self.init(sectionsWithItems.map { TreeNode(ChildValue(section: $0.0), $0.1.map { TreeNode(ChildValue(item: $0)) }) })
    }

    public subscript(itemAt index: IndexPath) -> ChildValue.Item {
        return self[index].value.item!
    }

    public subscript(sectionAt index: Int) -> ChildValue.Section {
        return self[[index]].value.section!
    }
}

/// A section or an item in a 2D array.
public enum Array2DElement<Section, Item>: Array2DElementProtocol {

    /// Section with the associated value of type `Section`.
    case section(Section)

    /// Item with the associated value of type `Item`.
    case item(Item)

    public init(item: Item) {
        self = .item(item)
    }

    public init(section: Section) {
        self = .section(section)
    }

    public var section: Section? {
        if case .section(let section) = self {
            return section
        } else {
            return nil
        }
    }

    public var item: Item? {
        if case .item(let item) = self {
            return item
        } else {
            return nil
        }
    }

    public var asArray2DElement: Array2DElement<Section, Item> {
        return self
    }
}

public protocol Array2DElementProtocol {
    associatedtype Section
    associatedtype Item
    init(section: Section)
    init(item: Item)
    var section: Section? { get }
    var item: Item?  { get }
    var asArray2DElement: Array2DElement<Section, Item> { get }
}
