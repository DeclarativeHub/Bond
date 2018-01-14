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
import ReactiveKit
import Differ

public enum Observable2DArrayChange {
    case reset

    case insertItems([IndexPath])
    case deleteItems([IndexPath])
    case updateItems([IndexPath])
    case moveItem(IndexPath, IndexPath)

    case insertSections(IndexSet)
    case deleteSections(IndexSet)
    case updateSections(IndexSet)
    case moveSection(Int, Int)

    case beginBatchEditing
    case endBatchEditing
}

public protocol Observable2DArrayEventProtocol {
    associatedtype SectionMetadata
    associatedtype Item
    var change: Observable2DArrayChange { get }
    var source: Observable2DArray<SectionMetadata, Item> { get }
}

public struct Observable2DArrayEvent<SectionMetadata, Item>: Observable2DArrayEventProtocol {
    public let change: Observable2DArrayChange
    public let source: Observable2DArray<SectionMetadata, Item>

    public init(change: Observable2DArrayChange, source: Observable2DArray<SectionMetadata, Item>) {
        self.change = change
        self.source = source
    }

    public init(change: Observable2DArrayChange, source: [Observable2DArraySection<SectionMetadata, Item>]) {
        self.change = change
        self.source = Observable2DArray(source)
    }
}

public struct Observable2DArrayPatchEvent<SectionMetadata, Item>: Observable2DArrayEventProtocol {
    public let change: Observable2DArrayChange
    public let source: Observable2DArray<SectionMetadata, Item>

    public init(change: Observable2DArrayChange, source: Observable2DArray<SectionMetadata, Item>) {
        self.change = change
        self.source = source
    }

    public init(change: Observable2DArrayChange, source: [Observable2DArraySection<SectionMetadata, Item>]) {
        self.change = change
        self.source = Observable2DArray(source)
    }
}

/// Represents a section in 2D array.
/// Section contains its metadata (e.g. header string) and items.
public struct Observable2DArraySection<Metadata, Item>: Collection {

    public var metadata: Metadata
    public var items: [Item]

    public init(metadata: Metadata, items: [Item] = []) {
        self.metadata = metadata
        self.items = items
    }

    public var startIndex: Int {
        return items.startIndex
    }

    public var endIndex: Int {
        return items.endIndex
    }

    public var count: Int {
        return items.count
    }

    public var isEmpty: Bool {
        return items.isEmpty
    }

    public func index(after i: Int) -> Int {
        return items.index(after: i)
    }

    public subscript(index: Int) -> Item {
        get {
            return items[index]
        }
    }

}

public class Observable2DArray<SectionMetadata, Item>: SignalProtocol {

    public fileprivate(set) var sections: [Observable2DArraySection<SectionMetadata, Item>]
    fileprivate let subject = PublishSubject<Observable2DArrayEvent<SectionMetadata, Item>, NoError>()
    fileprivate let lock = NSRecursiveLock(name: "com.reactivekit.bond.observable2darray")

    public init(_ sections:  [Observable2DArraySection<SectionMetadata, Item>] = []) {
        self.sections = sections
    }

    public var numberOfSections: Int {
        return sections.count
    }

    public func numberOfItems(inSection section: Int) -> Int {
        guard section < numberOfSections else { return 0 }
        return sections[section].items.count
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
        return IndexPath(item: 0, section: numberOfSections)
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

    public subscript(index: IndexPath) -> Item {
        get {
            return sections[index.section].items[index.item]
        }
    }

    public subscript(index: Int) -> Observable2DArraySection<SectionMetadata, Item> {
        get {
            return sections[index]
        }
    }

    public func observe(with observer: @escaping (Event<Observable2DArrayEvent<SectionMetadata, Item>, NoError>) -> Void) -> Disposable {
        observer(.next(Observable2DArrayEvent(change: .reset, source: self)))
        return subject.observe(with: observer)
    }
}

extension Observable2DArray: Deallocatable {

    public var deallocated: Signal<Void, NoError> {
        return subject.disposeBag.deallocated
    }
}

public class MutableObservable2DArray<SectionMetadata, Item>: Observable2DArray<SectionMetadata, Item> {

    /// Append new section at the end of the 2D array.
    public func appendSection(_ section: Observable2DArraySection<SectionMetadata, Item>) {
        lock.lock(); defer { lock.unlock() }
        sections.append(section)
        let sectionIndex = sections.count - 1
        let indices = 0..<section.items.count
        let indexPaths = indices.map { IndexPath(item: $0, section: sectionIndex) }
        if indices.count > 0 {
            subject.next(Observable2DArrayEvent(change: .beginBatchEditing, source: self))
            subject.next(Observable2DArrayEvent(change: .insertSections([sectionIndex]), source: self))
            subject.next(Observable2DArrayEvent(change: .insertItems(indexPaths), source: self))
            subject.next(Observable2DArrayEvent(change: .endBatchEditing, source: self))
        } else {
            subject.next(Observable2DArrayEvent(change: .insertSections([sectionIndex]), source: self))
        }
    }

    /// Append `item` to the section `section` of the array.
    public func appendItem(_ item: Item, toSection section: Int) {
        lock.lock(); defer { lock.unlock() }
        sections[section].items.append(item)
        let indexPath = IndexPath(item: sections[section].items.count - 1, section: section)
        subject.next(Observable2DArrayEvent(change: .insertItems([indexPath]), source: self))
    }

    /// Insert section at `index` with `items`.
    public func insert(section: Observable2DArraySection<SectionMetadata, Item>, at index: Int)  {
        lock.lock(); defer { lock.unlock() }
        sections.insert(section, at: index)
        let indices = 0..<section.items.count
        let indexPaths = indices.map { IndexPath(item: $0, section: index) }
        if indices.count > 0 {
            subject.next(Observable2DArrayEvent(change: .beginBatchEditing, source: self))
            subject.next(Observable2DArrayEvent(change: .insertSections([index]), source: self))
            subject.next(Observable2DArrayEvent(change: .insertItems(indexPaths), source: self))
            subject.next(Observable2DArrayEvent(change: .endBatchEditing, source: self))
        } else {
            subject.next(Observable2DArrayEvent(change: .insertSections([index]), source: self))
        }
    }

    /// Insert `item` at `indexPath`.
    public func insert(item: Item, at indexPath: IndexPath)  {
        lock.lock(); defer { lock.unlock() }
        sections[indexPath.section].items.insert(item, at: indexPath.item)
        subject.next(Observable2DArrayEvent(change: .insertItems([indexPath]), source: self))
    }

    /// Insert `items` at index path `indexPath`.
    public func insert(contentsOf items: [Item], at indexPath: IndexPath) {
        lock.lock(); defer { lock.unlock() }
        sections[indexPath.section].items.insert(contentsOf: items, at: indexPath.item)
        let indices = indexPath.item..<indexPath.item+items.count
        let indexPaths = indices.map { IndexPath(item: $0, section: indexPath.section) }
        subject.next(Observable2DArrayEvent(change: .insertItems(indexPaths), source: self))
    }

    /// Move the section at index `fromIndex` to index `toIndex`.
    public func moveSection(from fromIndex: Int, to toIndex: Int) {
        lock.lock(); defer { lock.unlock() }
        let section = sections.remove(at: fromIndex)
        sections.insert(section, at: toIndex)
        subject.next(Observable2DArrayEvent(change: .moveSection(fromIndex, toIndex), source: self))
    }

    /// Move the item at `fromIndexPath` to `toIndexPath`.
    public func moveItem(from fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        lock.lock(); defer { lock.unlock() }
        let item = sections[fromIndexPath.section].items.remove(at: fromIndexPath.item)
        sections[toIndexPath.section].items.insert(item, at: toIndexPath.item)
        subject.next(Observable2DArrayEvent(change: .moveItem(fromIndexPath, toIndexPath), source: self))
    }

    /// Remove and return the section at `index`.
    @discardableResult
    public func removeSection(at index: Int) -> Observable2DArraySection<SectionMetadata, Item> {
        lock.lock(); defer { lock.unlock() }
        let element = sections.remove(at: index)
        subject.next(Observable2DArrayEvent(change: .deleteSections([index]), source: self))
        return element
    }

    /// Remove and return the item at `indexPath`.
    @discardableResult
    public func removeItem(at indexPath: IndexPath) -> Item {
        lock.lock(); defer { lock.unlock() }
        let element = sections[indexPath.section].items.remove(at: indexPath.item)
        subject.next(Observable2DArrayEvent(change: .deleteItems([indexPath]), source: self))
        return element
    }

    /// Remove all items from the array. Keep empty sections.
    public func removeAllItems() {
        lock.lock(); defer { lock.unlock() }
        let indexPaths = sections.enumerated().reduce([]) { (indexPaths, section) -> [IndexPath] in
            indexPaths + section.element.items.indices.map { IndexPath(item: $0, section: section.offset) }
        }

        for index in sections.indices {
            sections[index].items.removeAll()
        }

        subject.next(Observable2DArrayEvent(change: .deleteItems(indexPaths), source: self))
    }

    /// Remove all items and sections from the array.
    public func removeAllItemsAndSections() {
        lock.lock(); defer { lock.unlock() }
        let indices = sections.indices
        sections.removeAll()
        subject.next(Observable2DArrayEvent(change: .deleteSections(IndexSet(integersIn: indices)), source: self))
    }

    public override subscript(index: IndexPath) -> Item {
        get {
            return sections[index.section].items[index.item]
        }
        set {
            lock.lock(); defer { lock.unlock() }
            sections[index.section].items[index.item] = newValue
            subject.next(Observable2DArrayEvent(change: .updateItems([index]), source: self))
        }
    }

    /// Change the underlying value withouth notifying the observers.
    public func silentUpdate(_ update: (inout [Observable2DArraySection<SectionMetadata, Item>]) -> Void) {
        lock.lock(); defer { lock.unlock() }
        update(&sections)
    }
}

extension MutableObservable2DArray: BindableProtocol {

    public func bind(signal: Signal<Observable2DArrayEvent<SectionMetadata, Item>, NoError>) -> Disposable {
        return signal
            .take(until: deallocated)
            .observeNext { [weak self] event in
                guard let s = self else { return }
                s.sections = event.source.sections
                s.subject.next(Observable2DArrayEvent(change: event.change, source: s))
            }
    }
}

// MARK: DataSourceProtocol conformation

extension Observable2DArrayChange {

    public var asDataSourceEventKind: DataSourceEventKind {
        switch self {
        case .reset:
            return .reload
        case .insertItems(let indexPaths):
            return .insertItems(indexPaths)
        case .deleteItems(let indexPaths):
            return .deleteItems(indexPaths)
        case .updateItems(let indexPaths):
            return .reloadItems(indexPaths)
        case .moveItem(let from, let to):
            return .moveItem(from, to)
        case .insertSections(let indices):
            return .insertSections(indices)
        case .deleteSections(let indices):
            return .deleteSections(indices)
        case .updateSections(let indices):
            return .reloadSections(indices)
        case .moveSection(let from, let to):
            return .moveSection(from, to)
        case .beginBatchEditing:
            return .beginUpdates
        case .endBatchEditing:
            return .endUpdates
        }
    }
}

extension Observable2DArrayEvent: DataSourceEventProtocol {

    public typealias BatchKind = BatchKindDiff

    public var kind: DataSourceEventKind {
        return change.asDataSourceEventKind
    }

    public var dataSource: Observable2DArray<SectionMetadata, Item> {
        return source
    }
}

extension Observable2DArrayPatchEvent: DataSourceEventProtocol {

    public typealias BatchKind = BatchKindPatch

    public var kind: DataSourceEventKind {
        return change.asDataSourceEventKind
    }

    public var dataSource: Observable2DArray<SectionMetadata, Item> {
        return source
    }
}

extension Observable2DArray: QueryableDataSourceProtocol {

    public func item(at index: IndexPath) -> Item {
        return self[index]
    }
}

extension MutableObservable2DArray {

    /// Replace section at given index with given section and notify observers to reload section completely
    public func replaceSection(at index: Int, with section: Observable2DArraySection<SectionMetadata, Item>)  {
        lock.lock(); defer { lock.unlock() }
        sections[index] = section
        subject.next(Observable2DArrayEvent(change: .updateSections([index]), source: self))
    }

    /// Replace the entier 2d array with a new one forcing a reload
    public func replace(with array: Observable2DArray<SectionMetadata, Item>)  {
        lock.lock(); defer { lock.unlock() }
        sections = array.sections
        subject.next(Observable2DArrayEvent(change: .reset, source: self))
    }
}

extension MutableObservable2DArray where Item: Equatable {

    /// Replace section at given index with given section performing diff if performDiff is true
    /// on all items in section and notifying observers about delets and inserts
    public func replaceSection(at index: Int, with section: Observable2DArraySection<SectionMetadata, Item>, performDiff: Bool) {
        if performDiff {
            lock.lock()
            let diff = sections[index].items.extendedDiff(section.items)
            let patch = diff.patch(from: sections[index].items, to: section.items)

            subject.next(Observable2DArrayEvent(change: .beginBatchEditing, source: self))
            sections[index].metadata = section.metadata
            sections[index].items = section.items

            for step in patch {
                switch step {
                case .insertion(let patchIndex, _):
                    let indexPath = IndexPath(item: patchIndex, section: index)
                    subject.next(Observable2DArrayEvent(change: .insertItems([indexPath]), source: self))

                case .deletion(let patchIndex):
                    let indexPath = IndexPath(item: patchIndex, section: index)
                    subject.next(Observable2DArrayEvent(change: .deleteItems([indexPath]), source: self))

                case .move(let from, let to):
                    let fromIndexPath = IndexPath(item: from, section: index)
                    let toIndexPath = IndexPath(item: to, section: index)

                    subject.next(Observable2DArrayEvent(change: .moveItem(fromIndexPath, toIndexPath), source: self))

                }
            }

            subject.next(Observable2DArrayEvent(change: .endBatchEditing, source: self))
            lock.unlock()
        } else {
            replaceSection(at: index, with: section)
        }
    }

    /// Replace all items in section at given index with given items performing diff between
    /// existing and new items if performDiff is true, otherwise reload section with new items
    public func replaceSection(at index: Int, with items: [Item], performDiff: Bool) {
        replaceSection(at: index, with: Observable2DArraySection<SectionMetadata, Item>(metadata: sections[index].metadata, items: items), performDiff: performDiff)
    }
}

extension MutableObservable2DArray where Item: Equatable, SectionMetadata: Equatable {

    /// Perform batched updates on the array.
    public func batchUpdate(_ update: (MutableObservable2DArray<SectionMetadata, Item>) -> Void) {
        let copy = MutableObservable2DArray(sections)
        update(copy)
        replace(with: copy, performDiff: true)
    }

    /// Replace the entire 2DArray performing nested diff (if preformDiff is true) on all
    /// sections and section's items resulting in a series of events (deleteSection,
    /// deleteItems, insertSections, insertItems, moveSection, moveItem) that migrate the old
    /// 2DArray to the new 2DArray
    /// Note that both Item and SectionMetadata should be Equatable
    public func replace(with array: Observable2DArray<SectionMetadata, Item>, performDiff: Bool) {

        if performDiff {

            lock.lock()

            // perform nested diff
            let diff = sections.nestedExtendedDiff(to: array.sections, isEqualSection: {(oldSection, newSection) in
                return oldSection.metadata == newSection.metadata
            })

            let update = NestedBatchUpdate(diff: diff)

            subject.next(Observable2DArrayEvent(change: .beginBatchEditing, source: self))
            sections = array.sections

            // item deletion
            subject.next(Observable2DArrayEvent(change: .deleteItems(update.itemDeletions), source: self))

            // item insertions
            subject.next(Observable2DArrayEvent(change: .insertItems(update.itemInsertions), source: self))

            // item moves
            update.itemMoves.forEach {
                subject.next(Observable2DArrayEvent(change: .moveItem($0.from, $0.to) , source: self))
            }

            // section deletion
            subject.next(Observable2DArrayEvent(change: .deleteSections(update.sectionDeletions), source: self))

            // section insertions
            subject.next(Observable2DArrayEvent(change: .insertSections(update.sectionInsertions), source: self))

            // section moves
            update.sectionMoves.forEach {
                subject.next(Observable2DArrayEvent(change: .moveSection($0.from, $0.to), source: self))
            }

            subject.next(Observable2DArrayEvent(change: .endBatchEditing, source: self))
            lock.unlock()
        } else {
            replace(with: array)
        }
    }
}

fileprivate struct NestedBatchUpdate {
    let itemDeletions: [IndexPath]
    let itemInsertions: [IndexPath]
    let itemMoves: [(from: IndexPath, to: IndexPath)]
    let sectionDeletions: IndexSet
    let sectionInsertions: IndexSet
    let sectionMoves: [(from: Int, to: Int)]

    init(diff: NestedExtendedDiff) {

        var itemDeletions: [IndexPath] = []
        var itemInsertions: [IndexPath] = []
        var itemMoves: [(IndexPath, IndexPath)] = []
        var sectionDeletions: IndexSet = []
        var sectionInsertions: IndexSet = []
        var sectionMoves: [(from: Int, to: Int)] = []

        diff.forEach { element in
            switch element {
            case let .deleteElement(at, section):
                itemDeletions.append(IndexPath(item: at, section: section))
            case let .insertElement(at, section):
                itemInsertions.append(IndexPath(item: at, section: section))
            case let .moveElement(from, to):
                itemMoves.append((IndexPath(item: from.item, section: from.section), IndexPath(item: to.item, section: to.section)))
            case let .deleteSection(at):
                sectionDeletions.insert(at)
            case let .insertSection(at):
                sectionInsertions.insert(at)
            case let .moveSection(move):
                sectionMoves.append(move)
            }
        }

        self.itemInsertions = itemInsertions
        self.itemDeletions = itemDeletions
        self.itemMoves = itemMoves
        self.sectionMoves = sectionMoves
        self.sectionInsertions = sectionInsertions
        self.sectionDeletions = sectionDeletions
    }
}

public extension SignalProtocol where Element: Observable2DArrayEventProtocol {

    /// Converts diff events into patch events by transforming batch updates into resets (i.e. disabling batch updates).
    public func toPatchesByResettingBatch() -> Signal<Observable2DArrayPatchEvent<Element.SectionMetadata, Element.Item>, Error> {

        var isBatching = false

        return Signal { observer in
            return self.observe { event in
                switch event {
                case .next(let observableArrayEvent):

                    let source = observableArrayEvent.source
                    switch observableArrayEvent.change {
                    case .beginBatchEditing:
                        isBatching = true
                    case .endBatchEditing:
                        isBatching = false
                        observer.next(.init(change: .reset, source: source))
                    default:
                        if !isBatching {
                            observer.next(.init(change: observableArrayEvent.change, source: source))
                        }
                    }

                case .failed(let error):
                    observer.failed(error)

                case .completed:
                    observer.completed()
                }
            }
        }
    }
}
