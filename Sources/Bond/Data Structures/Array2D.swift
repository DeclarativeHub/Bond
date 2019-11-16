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

public protocol Array2DProtocol: RangeReplaceableTreeProtocol where Children == [Array2D<SectionMetadata, Item>.Node] {
    associatedtype SectionMetadata
    associatedtype Item
}

/// A data structure whose items are grouped into section.
/// Array2D can be used as an underlying data structure for UITableView or UICollectionView data source.
public struct Array2D<SectionMetadata, Item>: Array2DProtocol {

    /// Represents a single section of Array2D.
    public struct Section {

        /// Section metadata, e.g. section title.
        public var metadata: SectionMetadata

        /// Items contained in the section.
        public var items: [Item]

        public init(metadata: SectionMetadata, items: [Item]) {
            self.metadata = metadata
            self.items = items
        }
    }

    /// All sections of Array2D.
    public var sections: [Section]

    /// Create a new Array2D with the given sections.
    public init(sections: [Section] = []) {
        self.sections = sections
    }
}

// MARK: Convenience methods

extension Array2D {

    /// Create a new Array2D from the given list of section metadata and respective items.
    /// Each SectionMetadata corresponds to one section populated with the given items.
    public init(sectionsWithItems: [(SectionMetadata, [Item])]) {
        self.init(sections: sectionsWithItems.map { Section(metadata: $0.0, items: $0.1) })
    }

    /// Access or mutate an item at the given index path.
    public subscript(itemAt indexPath: IndexPath) -> Item {
        get {
            return sections[indexPath.section].items[indexPath.item]
        }
        set {
            sections[indexPath.section].items[indexPath.item] = newValue
        }
    }

    /// Access or mutate a section at the given index.
    public subscript(sectionAt index: Int) -> Section {
        get {
            return sections[index]
        }
        set {
            sections[index] = newValue
        }
    }

    /// Append new section at the end of the 2D array.
    public mutating func appendSection(_ section: Section) {
        sections.append(section)
    }

    /// Append new section at the end of the 2D array.
    public mutating func appendSection(_ metadata: SectionMetadata) {
        sections.append(Section(metadata: metadata, items: []))
    }


    /// Append `item` to the section `section` of the array.
    public mutating func appendItem(_ item: Item, toSectionAt sectionIndex: Int) {
        sections[sectionIndex].items.append(item)
    }

    /// Insert section at `index` with `items`.
    public mutating func insert(section: Section, at index: Int)  {
        sections.insert(section, at: index)
    }

    /// Insert section at `index` with `items`.
    public mutating func insert(section metadata: SectionMetadata, at index: Int)  {
        sections.insert(Section(metadata: metadata, items: []), at: index)
    }

    /// Insert `item` at `indexPath`.
    public mutating func insert(item: Item, at indexPath: IndexPath)  {
        sections[indexPath.section].items.insert(item, at: indexPath.item)
    }

    /// Insert `items` at index path `indexPath`.
    public mutating func insert(contentsOf items: [Item], at indexPath: IndexPath) {
        sections[indexPath.section].items.insert(contentsOf: items, at: indexPath.item)
    }

    /// Move the section at index `fromIndex` to index `toIndex`.
    public mutating func moveSection(from fromIndex: Int, to toIndex: Int) {
        sections.move(from: fromIndex, to: toIndex)
    }

    /// Move the item at `fromIndexPath` to `toIndexPath`.
    public mutating func moveItem(from fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        let item = sections[fromIndexPath.section].items.remove(at: fromIndexPath.item)
        sections[toIndexPath.section].items.insert(item, at: toIndexPath.item)
    }

    /// Remove and return the section at `index`.
    @discardableResult
    public mutating func removeSection(at index: Int) -> Section {
        return sections.remove(at: index)
    }

    /// Remove and return the item at `indexPath`.
    @discardableResult
    public mutating func removeItem(at indexPath: IndexPath) -> Item {
        return sections[indexPath.section].items.remove(at: indexPath.item)
    }

    /// Remove all items from the array. Keep empty sections.
    public mutating func removeAllItems() {
        for index in 0..<sections.count {
            sections[index].items.removeAll()
        }
    }

    /// Remove all items and sections from the array (aka `removeAll`).
    public mutating func removeAllItemsAndSections() {
        sections.removeAll()
    }
}

// MARK: TreeProtocol conformance

extension Array2D {

    /// A type that represents a node of Array2D tree - either a section or an item.
    public enum Node: RangeReplaceableTreeProtocol {
        case section(Section)
        case item(Item)

        /// Child nodes of the element. In case of a section, children are its items. In case of an item, empty array.
        public var children: [Node] {
            get {
                switch self {
                case .section(let section):
                    return section.items.map { Node.item($0) }
                case .item:
                    return []
                }
            }
            set {
                switch self {
                case .section(let section):
                    self = .section(Section(metadata: section.metadata, items: newValue.compactMap { $0.item }))
                case .item:
                    break
                }
            }
        }

        /// A section if the node represents a section node, nil otherwise.
        public var section: Section? {
            switch self {
            case .section(let section):
                return section
            default:
                return nil
            }
        }

        /// An item if the node represents an item node, nil otherwise.
        public var item: Item? {
            switch self {
            case .item(let item):
                return item
            default:
                return nil
            }
        }
    }

    /// Child nodes of the Array2D tree. First level of the tree are sections, while the second level are items.
    public var children: [Node] {
        get {
            return sections.map { Node.section($0) }
        }
        set {
            sections = newValue.compactMap { $0.section }
        }
    }
}
