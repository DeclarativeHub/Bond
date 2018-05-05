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

public protocol Array2DProtocol: RangeReplaceableCollection {
    associatedtype Value
    associatedtype Item
    var array2DView: Array2D<Value, Item> { get set }
}

public struct Array2D<Value, Item>: Array2DProtocol {

    public struct Section: MutableCollection {

        public var value: Value
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
    }

    public var sections: [Section]

    public init() {
        self.sections = []
    }

    public init(sections: [Section] = []) {
        self.sections = sections
    }

    public var startIndex: IndexPath {
        guard sections.count > 0 else { return IndexPath(item: 0, section: 0) }
        var section = 0
        while section < sections.count && sections[section].count == 0 {
            section += 1
        }
        return IndexPath(item: 0, section: section)
    }

    public var endIndex: IndexPath {
        return IndexPath(item: 0, section: sections.count)
    }

    public func index(after i: IndexPath) -> IndexPath {
        if i.section < sections.count {
            let section = sections[i.section]
            if i.item + 1 < section.items.count {
                return IndexPath(item: i.item + 1, section: i.section)
            } else {
                var section = i.section + 1
                while section < sections.count {
                    if sections[section].items.count > 0 {
                        return IndexPath(item: 0, section: section)
                    } else {
                        section += 1
                    }
                }
                return endIndex
            }
        } else {
            return endIndex
        }
    }

    public var isEmpty: Bool {
        return sections.reduce(true) { $0 && $1.items.isEmpty }
    }

    public var count: Int {
        return sections.reduce(0) { $0 + $1.items.count }
    }

    public subscript(indexPath: IndexPath) -> Item {
        get {
            return sections[indexPath.section].items[indexPath.item]
        }
        set {
            sections[indexPath.section].items[indexPath.item] = newValue
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
}

extension MutableObservableCollection where UnderlyingCollection: Collection, UnderlyingCollection.Index == Int, UnderlyingCollection.Element: Array2DProtocol {
//
//    public typealias Value = UnderlyingCollection.Element.Value
//    public typealias Item = UnderlyingCollection.Element.Item
//
//    public subscript(itemAt indexPath: IndexPath) -> Item {
//        get {
//            return collection[indexPath.section].array2DSectionView[indexPath.item]
//        }
//        set {
//            descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
//                collection[itemAt: indexPath] = newValue
//                return [.update(at: indexPath)]
//            }
//        }
//    }

//    public subscript(sectionAt index: Int) -> Section {
//        get {
//            return collection[sectionAt: index]
//        }
//        set {
//            descriptiveUpdate { (collection) -> [CollectionOperation<IndexPath>] in
//                collection[sectionAt: index] = newValue
//                return [.update(at: IndexPath(indexes: [index]))]
//            }
//        }
//    }
}

//extension MutableObservableCollection where UnderlyingCollection: RangeReplacableTreeNode, UnderlyingCollection: Array2DProtocol {
//
//    /// Append new section at the end of the 2D array.
//    public func appendSection(_ section: Section, withItems items: [Item] = []) {
//        append(UnderlyingCollection(section: section, items: items))
//    }
//
//    /// Append `item` to the section `section` of the array.
//    public func appendItem(_ item: Item, toSection section: Int) {
//        batchUpdate(subtreeAt: IndexPath(index: section)) { (subtree) in
//            subtree.append(UnderlyingCollection(item: item))
//        }
//    }
//
//    /// Insert section at `index` with `items`.
//    public func insert(section: Section, withItems items: [Item], at index: Int)  {
//        insert(UnderlyingCollection(section: section, items: items), at: [index])
//    }
//
//    /// Insert `item` at `indexPath`.
//    public func insert(item: Item, at indexPath: IndexPath)  {
//        insert(UnderlyingCollection(item: item), at: indexPath)
//    }
//
//    /// Insert `items` at index path `indexPath`.
//    public func insert(contentsOf items: [Item], at indexPath: IndexPath) {
//        insert(contentsOf: items.map { UnderlyingCollection(item: $0) }, at: indexPath)
//    }
//
//    /// Move the section at index `fromIndex` to index `toIndex`.
//    public func moveSection(from fromIndex: Int, to toIndex: Int) {
//        move(from: [fromIndex], to: [toIndex])
//    }
//
//    /// Move the item at `fromIndexPath` to `toIndexPath`.
//    public func moveItem(from fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
//        move(from: fromIndexPath, to: toIndexPath)
//    }
//
//    /// Remove and return the section at `index`.
//    @discardableResult
//    public func removeSection(at index: Int) -> (section: Section, items: [Item]) {
//        let node = remove(at: [index])
//        return (node.value.array2DElementView.section!, node.children.map { $0.value.array2DElementView.item! })
//    }
//
//    /// Remove and return the item at `indexPath`.
//    @discardableResult
//    public func removeItem(at indexPath: IndexPath) -> Item {
//        let node = remove(at: indexPath)
//        return node.value.array2DElementView.item!
//    }
//
//    /// Remove all items from the array. Keep empty sections.
//    public func removeAllItems() {
//        batchUpdate { (section) in
//            for index in section.collection.indices {
//                section.batchUpdate(subtreeAt: index, { (section) in
//                    section.removeAll()
//                })
//            }
//        }
//    }
//
//    /// Remove all items and sections from the array.
//    public func removeAllItemsAndSections() {
//        removeAll()
//    }
//}
