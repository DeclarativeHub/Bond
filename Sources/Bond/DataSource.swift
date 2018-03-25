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

public protocol DataSourceProtocol {
    var numberOfSections: Int { get }
    func numberOfItems(inSection section: Int) -> Int
}

public enum DataSourceEventKind {
    case reload

    case insertItems([IndexPath])
    case deleteItems([IndexPath])
    case reloadItems([IndexPath])
    case moveItem(IndexPath, IndexPath)

    case insertSections(IndexSet)
    case deleteSections(IndexSet)
    case reloadSections(IndexSet)
    case moveSection(Int, Int)

    case beginUpdates
    case endUpdates
}

public protocol DataSourceBatchKind {}

public enum BatchKindDiff: DataSourceBatchKind {}
public enum BatchKindPatch: DataSourceBatchKind {}

public protocol DataSourceEventProtocol {
    associatedtype DataSource: DataSourceProtocol
    associatedtype BatchKind: DataSourceBatchKind

    /// Represents data source event kind like insertion, deletion, etc.
    var kind: DataSourceEventKind { get }

    /// The data source itself.
    var dataSource: DataSource { get }
}

extension DataSourceEventProtocol {

    public var _unbox: DataSourceEvent<DataSource, BatchKind> {
        if let event = self as? DataSourceEvent<DataSource, BatchKind> {
            return event
        } else {
            return DataSourceEvent(kind: self.kind, dataSource: self.dataSource)
        }
    }
}

public struct DataSourceEvent<DataSource: DataSourceProtocol, _BatchKind: DataSourceBatchKind>: DataSourceEventProtocol {
    public typealias BatchKind = _BatchKind

    public let kind: DataSourceEventKind
    public let dataSource: DataSource
}

extension Array: DataSourceProtocol {

    public var numberOfSections: Int {
        return 1
    }

    public func numberOfItems(inSection section: Int) -> Int {
        return count
    }
}

extension Array: DataSourceEventProtocol, ObservableArrayEventProtocol {

    public typealias BatchKind = BatchKindDiff

    public var kind: DataSourceEventKind {
        return .reload
    }

    public var dataSource: Array<Element> {
        return self
    }

    public var change: ObservableArrayChange {
        return .reset
    }

    public var source: ObservableArray<Iterator.Element> {
        return ObservableArray(self)
    }
}

extension SignalProtocol where Element: DataSourceProtocol, Error == NoError {

    public func mapToDataSourceEvent() -> SafeSignal<DataSourceEvent<Element, BatchKindDiff>> {
        return map { collection in DataSourceEvent(kind: .reload, dataSource: collection) }
    }
}

