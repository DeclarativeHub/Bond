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

extension TreeArray where ChildValue: Array2DElementProtocol {

    public init(sectionsWithItems: [(ChildValue.Section, [ChildValue.Item])]) {
        self.init(sectionsWithItems.map { TreeNode(ChildValue(section: $0.0), $0.1.map { TreeNode(ChildValue(item: $0)) }) })
    }

    public subscript(itemAt indexPath: IndexPath) -> ChildValue.Item {
        get {
            return self[indexPath].value.item!
        }
        set {
            self[indexPath].value = ChildValue(item: newValue)
        }
    }

    public subscript(sectionAt index: Int) -> ChildValue.Section {
        get {
            return self[[index]].value.section!
        }
        set {
            self[[index]].value = ChildValue(section: newValue)
        }
    }

    /// Append new section at the end of the 2D array.
    public mutating func appendSection(_ section: ChildValue.Section) {
        append(TreeNode(ChildValue(section: section)))
    }

    /// Append `item` to the section `section` of the array.
    public mutating func appendItem(_ item: ChildValue.Item, toSectionAt sectionIndex: Int) {
        insert(item: item, at: [sectionIndex, self[[sectionIndex]].children.count])
    }

    /// Insert section at `index` with `items`.
    public mutating func insert(section: ChildValue.Section, at index: Int)  {
        insert(TreeNode(ChildValue(section: section)), at: [index])
    }

    /// Insert `item` at `indexPath`.
    public mutating func insert(item: ChildValue.Item, at indexPath: IndexPath)  {
        insert(TreeNode(ChildValue(item: item)), at: indexPath)
    }

    /// Insert `items` at index path `indexPath`.
    public mutating func insert(contentsOf items: [ChildValue.Item], at indexPath: IndexPath) {
        insert(contentsOf: items.map { TreeNode(ChildValue(item: $0)) }, at: indexPath)
    }

    /// Move the section at index `fromIndex` to index `toIndex`.
    public mutating func moveSection(from fromIndex: Int, to toIndex: Int) {
        move(from: [fromIndex], to: [toIndex])
    }

    /// Move the item at `fromIndexPath` to `toIndexPath`.
    public mutating func moveItem(from fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        move(from: fromIndexPath, to: toIndexPath)
    }

    /// Remove and return the section at `index`.
    @discardableResult
    public mutating func removeSection(at index: Int) -> ChildValue.Section {
        return remove(at: [index]).value.section!
    }

    /// Remove and return the item at `indexPath`.
    @discardableResult
    public mutating func removeItem(at indexPath: IndexPath) -> ChildValue.Item {
        return remove(at: indexPath).value.item!
    }

    /// Remove all items from the array. Keep empty sections.
    public mutating func removeAllItems() {
        for index in indices {
            self[index].removeAll()
        }
    }

    /// Remove all items and sections from the array (aka `removeAll`).
    public mutating func removeAllItemsAndSections() {
        removeAll()
    }
}
