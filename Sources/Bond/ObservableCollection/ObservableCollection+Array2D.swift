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

import Foundation

public protocol Array2DProtocol: RangeReplaceableCollection where Index == IndexPath, Element == Array2D<Value, Item>.Element {
    associatedtype Value
    associatedtype Item
    var array2DView: Array2D<Value, Item> { get set }
}

/// An array of items of type `Array2D.Item` grouped into sections of type `Array2D.Section`.
/// Elements of this collection are of enum type `Array2D.Element`. Iterating a 2D array visits
/// all sections and all items in depth-first search order.
///
/// Generic argument `Item` specifies the type of the items in the 2D array.
///
/// Generic argument `Value` specifies the type of the section value of the 2D array. If you are
/// for example binding an `ObservableArray<Array2D>` to a `UITable/CollectionView` then you could constrain
/// `Value` to `String` to provide section titles. When no section data is needed or available, constrain it to `Void`.
///
/// To access item at the given index path do:
/// ```
/// array2d[itemAt: indexPath] = "Updated"
/// ```
///
/// To access section at the given index do:
/// ```
/// array2d[sectionAt: index] = Array2D.Section("Title")
/// ```
public struct Array2D<Value, Item>: Array2DProtocol, CustomDebugStringConvertible {

    /// Represents a section in 2D array.
    public struct Section: MutableCollection, CustomDebugStringConvertible {

        /// A section value. Can be constraint to `Void` when no value is available.
        public var value: Value

        /// Items of the section.
        public var items: [Item]

        public init(value: Value, items: [Item] = []) {
            self.value = value
            self.items = items
        }

        public var startIndex: Int {
            return items.startIndex
        }

        public var endIndex: Int {
            return items.endIndex
        }

        public func index(after i: Int) -> Int {
            return items.index(after: i)
        }

        public subscript(index: Int) -> Item {
            get {
                return items[index]
            }
            set {
                items[index] = newValue
            }
        }

        public var debugDescription: String {
            return "\(value): \(items.debugDescription)"
        }
    }

    /// Array2D is a collection of `Array2D.Element` elements.
    /// An element can be either a section or an item.
    public enum Element {
        case section(Section)
        case item(Item)

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
    }

    /// Sections of te 2D array.
    public var sections: [Section]

    public init() {
        self.sections = []
    }

    public init(sections: [Section]) {
        self.sections = sections
    }

    public var startIndex: IndexPath {
        return IndexPath(index: 0)
    }

    public var endIndex: IndexPath {
        return IndexPath(index: sections.count)
    }

    public func index(after i: IndexPath) -> IndexPath {
        if i.count == 1 {
            if i[0] < sections.count {
                let section = sections[i[0]]
                if section.count > 0 {
                    return IndexPath(item: 0, section: i[0])
                }  else {
                    return IndexPath(index: i[0] + 1)
                }
            } else {
                return endIndex
            }
        } else if i.count == 2 {
            if i.item < sections[i.section].count - 1 {
                return IndexPath(item: i.item + 1, section: i.section)
            } else {
                return IndexPath(index: i.section + 1)
            }
        } else {
            fatalError()
        }
    }

    /// A 2D array is empty if there are neither sections nor items in the array.
    /// A 2D array that has at least one section is not considered empty even if
    /// all its sections have zero items.
    public var isEmpty: Bool {
        return count == 0
    }

    /// Total number of sections and items combined. For example, if the array
    /// contains one section with one item, then the count value will be 2.
    public var count: Int {
        return sections.reduce(0) { $0 + $1.items.count + 1 }
    }

    public subscript(indexPath: IndexPath) -> Element {
        get {
            if indexPath.count == 1 {
                return .section(sections[indexPath[0]])
            } else if indexPath.count == 2 {
                return .item(sections[indexPath.section].items[indexPath.item])
            } else {
                fatalError()
            }
        }
        set {
            switch (indexPath.count, newValue) {
            case (1, .section(let section)):
                sections[indexPath.section] = section
            case (2, .item(let item)):
                sections[indexPath.section].items[indexPath.item] = item
            default:
                fatalError()
            }
        }
    }

    /// Access item at the given index path.
    public subscript(itemAt indexPath: IndexPath) -> Item {
        get {
            return sections[indexPath.section].items[indexPath.item]
        }
        set {
            sections[indexPath.section].items[indexPath.item] = newValue
        }
    }

    /// Access section at the given index.
    public subscript(sectionAt index: Int) -> Section {
        get {
            return sections[index]
        }
        set {
            sections[index] = newValue
        }
    }

    public mutating func replaceSubrange<C>(_ subrange: Range<IndexPath>, with newElements: C) where C: Collection, Array2D<Value, Item>.Element == C.Element {
        let lower = subrange.lowerBound
        let upper = subrange.upperBound
        if lower.count == 1 && index(after: lower) == upper && newElements.count == 0 {
            sections.remove(at: lower[0])
            return
        }
        guard upper.count == lower.count else {
            fatalError("Unsupproted range \(subrange). Plase replace only sections or only items within as single section.")
        }
        if lower.count == 1 {
            sections.replaceSubrange(lower[0]..<upper[0], with: newElements.map { $0.section! })
        } else if lower.count == 2 {
            sections[lower.section].items.replaceSubrange(lower.item..<upper.item, with: newElements.map { $0.item! })
        } else {
            fatalError("Unsupported index.")
        }
    }

    public var array2DView: Array2D<Value, Item> {
        get {
            return self
        }
        set {
            self = newValue
        }
    }

    public var debugDescription: String {
        return "[" + sections.map { $0.debugDescription }.joined(separator: ", ") + "]"
    }
}

extension MutableObservableCollection where UnderlyingCollection: Array2DProtocol {

    public typealias Value = UnderlyingCollection.Value
    public typealias Item = UnderlyingCollection.Item
    public typealias Section = Array2D<Value, Item>.Section
    public typealias Element = Array2D<Value, Item>.Element

    public subscript(itemAt indexPath: IndexPath) -> Item {
        get {
            return collection.array2DView[indexPath].item!
        }
        set {
            descriptiveUpdate { (collection) -> CollectionDiff<IndexPath> in
                collection.array2DView[indexPath] = .item(newValue)
                return CollectionDiff(updates: [indexPath], areIndicesPresorted: true)
            }
        }
    }

    public subscript(sectionAt index: Int) -> Section {
        get {
            return collection.array2DView.sections[index]
        }
        set {
            descriptiveUpdate { (collection) -> CollectionDiff<IndexPath> in
                collection.array2DView.sections[index] = newValue
                return CollectionDiff(updates: [[index]], areIndicesPresorted: true)
            }
        }
    }

    /// Append new section at the end of the 2D array.
    public func appendSection(_ section: Section) {
        append(.section(section))
    }

    /// Append `item` to the section `section` of the array.
    public func appendItem(_ item: Item, toSectionAt sectionIndex: Int) {
        let section = collection.array2DView.sections[sectionIndex]
        insert(item: item, at: IndexPath(item: section.count, section: sectionIndex))
    }

    /// Insert section at `index` with `items`.
    public func insert(section: Section, at index: Int)  {
        insert(.section(section), at: [index])
    }

    /// Insert `item` at `indexPath`.
    public func insert(item: Item, at indexPath: IndexPath)  {
        insert(.item(item), at: indexPath)
    }

    /// Insert `items` at index path `indexPath`.
    public func insert(contentsOf items: [Item], at indexPath: IndexPath) {
        insert(contentsOf: items.map { .item($0) }, at: indexPath)
    }

    /// Move the section at index `fromIndex` to index `toIndex`.
    public func moveSection(from fromIndex: Int, to toIndex: Int) {
        move(from: [fromIndex], to: [toIndex])
    }

    /// Move the item at `fromIndexPath` to `toIndexPath`.
    public func moveItem(from fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        move(from: fromIndexPath, to: toIndexPath)
    }

    /// Remove and return the section at `index`.
    @discardableResult
    public func removeSection(at index: Int) -> Section {
        return remove(at: [index]).section!
    }

    /// Remove and return the item at `indexPath`.
    @discardableResult
    public func removeItem(at indexPath: IndexPath) -> Item {
        return remove(at: indexPath).item!
    }

    /// Remove all items from the array. Keep empty sections.
    public func removeAllItems() {
        descriptiveUpdate { (collection) -> CollectionDiff<IndexPath> in
            let indices = collection.array2DView.indices.map { $0 }.filter { $0.count == 2 }
            for index in collection.array2DView.sections.indices {
                collection.array2DView.sections[index].items = []
            }
            return CollectionDiff(deletes: indices.reversed().map { $0 }, areIndicesPresorted: true)
        }
    }

    /// Remove all items and sections from the array.
    public func removeAllItemsAndSections() {
        removeAll()
    }
}
