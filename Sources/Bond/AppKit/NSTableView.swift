//
//  NSTableView.swift
//  Bond
//
//  Created by Srdan Rasic on 18/08/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

#if os(macOS)

import AppKit
import ReactiveKit

public extension ReactiveExtensions where Base: NSTableView {

    public var delegate: ProtocolProxy {
        return protocolProxy(for: NSTableViewDelegate.self, keyPath: \.delegate)
    }

    public var dataSource: ProtocolProxy {
        return protocolProxy(for: NSTableViewDataSource.self, keyPath: \.dataSource)
    }

    public var selectionIsChanging: SafeSignal<Void> {
        return NotificationCenter.default.reactive.notification(name: NSTableView.selectionIsChangingNotification, object: base).eraseType()
    }

    public var selectionDidChange: SafeSignal<Void> {
        return NotificationCenter.default.reactive.notification(name: NSTableView.selectionDidChangeNotification, object: base).eraseType()
    }

    public var selectedRowIndexes: Bond<IndexSet> {
        return bond { $0.selectRowIndexes($1, byExtendingSelection: false) }
    }

    public var selectedColumnIndexes: Bond<IndexSet> {
        return bond { $0.selectColumnIndexes($1, byExtendingSelection: false) }
    }
}

// MARK: - Bond declaration

public protocol TableViewBond {

    associatedtype DataSource: DataSourceProtocol

    func apply(event: DataSourceEvent<DataSource, BatchKindPatch>, to tableView: NSTableView)
    func heightForRow(at index: Int, tableView: NSTableView, dataSource: DataSource) -> CGFloat?
    func cellForRow(at index: Int, tableView: NSTableView, dataSource: DataSource) -> NSView?
}

extension TableViewBond {

    public func heightForRow(at index: Int, tableView: NSTableView, dataSource: DataSource) -> CGFloat? {
        return nil
    }

    public func apply(event: DataSourceEvent<DataSource, BatchKindPatch>, to tableView: NSTableView) {
        tableView.reloadData()
    }
}

// MARK: - Builtin bonds

open class DefaultTableViewBond<DataSource: DataSourceProtocol>: TableViewBond {

    private var updating: Bool = false

    public var insertAnimation: NSTableView.AnimationOptions? = [.effectFade, .slideUp]
    public var deleteAnimation: NSTableView.AnimationOptions? = [.effectFade, .slideUp]

    let measureCell: ((DataSource, Int, NSTableView) -> CGFloat?)?
    let createCell: ((DataSource, Int, NSTableView) -> NSView?)?

    public init() {
        // This initializer allows subclassing without having to declare default initializer in subclass.
        measureCell = nil
        createCell = nil
    }

    public init(measureCell: ((DataSource, Int, NSTableView) -> CGFloat?)? = nil, createCell: ((DataSource, Int, NSTableView) -> NSView?)? = nil) {
        self.measureCell = measureCell
        self.createCell = createCell
    }

    open func heightForRow(at index: Int, tableView: NSTableView, dataSource: DataSource) -> CGFloat? {
        return measureCell?(dataSource, index, tableView) ?? tableView.rowHeight
    }

    open func cellForRow(at index: Int, tableView: NSTableView, dataSource: DataSource) -> NSView? {
        return createCell?(dataSource, index, tableView) ?? nil
    }

    open func apply(event: DataSourceEvent<DataSource, BatchKindPatch>, to tableView: NSTableView) {
        if insertAnimation == nil && deleteAnimation == nil {
            tableView.reloadData()
            return
        }

        switch event.kind {
        case .reload:
            tableView.reloadData()
        case .insertItems(let indexPaths):
            let rowIndexes = IndexSet(indexPaths.map { $0.item })
            tableView.insertRows(at: rowIndexes, withAnimation: insertAnimation ?? [])
        case .deleteItems(let indexPaths):
            let rowIndexes = IndexSet(indexPaths.map { $0.item })
            tableView.removeRows(at: rowIndexes, withAnimation: deleteAnimation ?? [])
        case .reloadItems(let indexPaths):
            let rowIndexes = IndexSet(indexPaths.map { $0.item })
            let columnIndexes = IndexSet(tableView.tableColumns.enumerated().map { $0.0 })
            tableView.reloadData(forRowIndexes: rowIndexes, columnIndexes: columnIndexes)
        case .moveItem(let indexPath, let newIndexPath):
            tableView.moveRow(at: indexPath.item, to: newIndexPath.item)
        case .insertSections:
            fatalError("NSTableView binding does not support sections.")
        case .deleteSections:
            fatalError("NSTableView binding does not support sections.")
        case .reloadSections:
            fatalError("NSTableView binding does not support sections.")
        case .moveSection:
            fatalError("NSTableView binding does not support sections.")
        case .beginUpdates:
            tableView.beginUpdates()
            updating = true
        case .endUpdates:
            updating = false
            tableView.endUpdates()
        }
    }
}

private struct ReloadingTableViewBond<DataSource: DataSourceProtocol>: TableViewBond {

    let createCell: (DataSource, Int, NSTableView) -> NSView?

    func cellForRow(at index: Int, tableView: NSTableView, dataSource: DataSource) -> NSView? {
        return createCell(dataSource, index, tableView)
    }
}

// MARK: - Bond implementation

public extension SignalProtocol where
    Element: DataSourceEventProtocol, Element.BatchKind == BatchKindPatch,
Element.DataSource: QueryableDataSourceProtocol, Element.DataSource.Index == Int, Error == NoError {

    public typealias DataSource = Element.DataSource

    @discardableResult
    public func bind(to tableView: NSTableView, animated: Bool = true, createCell: @escaping (DataSource, Int, NSTableView) -> NSView?) -> Disposable {
        if animated {
            return bind(to: tableView, using: DefaultTableViewBond<DataSource>(createCell: createCell))
        } else {
            return bind(to: tableView, using: ReloadingTableViewBond<DataSource>(createCell: createCell))
        }
    }

    @discardableResult
    public func bind<B: TableViewBond>(to tableView: NSTableView, using bond: B) -> Disposable where B.DataSource == DataSource {
        return _bind(to: tableView, using: bond)
    }

    @discardableResult
    fileprivate func _bind<B: TableViewBond>(to tableView: NSTableView, using bond: B) -> Disposable where B.DataSource == DataSource {

        let dataSource = Property<DataSource?>(nil)
        let disposable = CompositeDisposable()

        disposable += tableView.reactive.delegate.feed(
            property: dataSource,
            to: #selector(NSTableViewDelegate.tableView(_:heightOfRow:)),
            map: { (dataSource: DataSource?, tableView: NSTableView, row: Int) -> CGFloat in
                guard let dataSource = dataSource else { return tableView.rowHeight }
                return bond.heightForRow(at: row, tableView: tableView, dataSource: dataSource) ?? tableView.rowHeight
            }
        )

        disposable += tableView.reactive.delegate.feed(
            property: dataSource,
            to: #selector(NSTableViewDelegate.tableView(_:viewFor:row:)),
            map: { (dataSource: DataSource?, tableView: NSTableView, _: NSTableColumn, row: Int) -> NSView? in
                guard let dataSource = dataSource else { return nil }
                return bond.cellForRow(at: row, tableView: tableView, dataSource: dataSource)
            }
        )

        disposable += tableView.reactive.dataSource.feed(
            property: dataSource,
            to: #selector(NSTableViewDataSource.numberOfRows(in:)),
            map: { (dataSource: DataSource?, _: NSTableView) -> Int in
                return dataSource?.numberOfItems(inSection: 0) ?? 0
            }
        )

        disposable += tableView.reactive.dataSource.feed(
            property: dataSource,
            to: #selector(NSTableViewDataSource.tableView(_:objectValueFor:row:)),
            map: { (dataSource: DataSource?, _: NSTableView, _: NSTableColumn, row: Int) -> Any? in
                return dataSource?.item(at: row)
            }
        )

        disposable += bind(to: tableView) { tableView, event in
            let event = event._unbox
            dataSource.value = event.dataSource
            bond.apply(event: event, to: tableView)
        }

        return disposable
    }
}

public extension SignalProtocol where Element: ObservableArrayEventProtocol, Error == NoError {

    @discardableResult
    public func bind(to tableView: NSTableView, animated: Bool = true, createCell: @escaping (ObservableArray<Element.Item>, Int, NSTableView) -> NSView?) -> Disposable {
        if animated {
            return toPatchesByResettingBatch()._bind(to: tableView, using: DefaultTableViewBond<ObservableArray<Element.Item>>(createCell: createCell))
        } else {
            return toPatchesByResettingBatch()._bind(to: tableView, using: ReloadingTableViewBond<ObservableArray<Element.Item>>(createCell: createCell))
        }
    }

    @discardableResult
    public func bind<B: TableViewBond>(to tableView: NSTableView, using bond: B) -> Disposable where B.DataSource == ObservableArray<Element.Item> {
        return toPatchesByResettingBatch()._bind(to: tableView, using: bond)
    }
}

public extension SignalProtocol where Element: ObservableArrayEventProtocol, Element.Item: Equatable, Error == NoError {

    @discardableResult
    public func bind(to tableView: NSTableView, animated: Bool = true, createCell: @escaping (ObservableArray<Element.Item>, Int, NSTableView) -> NSView?) -> Disposable {
        if animated {
            return toPatches()._bind(to: tableView, using: DefaultTableViewBond<ObservableArray<Element.Item>>(createCell: createCell))
        } else {
            return toPatches()._bind(to: tableView, using: ReloadingTableViewBond<ObservableArray<Element.Item>>(createCell: createCell))
        }
    }

    @discardableResult
    public func bind<B: TableViewBond>(to tableView: NSTableView, using bond: B) -> Disposable where B.DataSource == ObservableArray<Element.Item> {
        return toPatches()._bind(to: tableView, using: bond)
    }
}

#endif
