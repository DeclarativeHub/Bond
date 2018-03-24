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

#if os(iOS) || os(tvOS)

    import UIKit
    import ReactiveKit

    public extension ReactiveExtensions where Base: UITableView {

        /// A `ProtocolProxy` for the table view delegate.
        ///
        /// - Note: Accessing this property for the first time will replace table view's current delegate
        /// with a protocol proxy object (an object that is stored in this property).
        /// Current delegate will be used as `forwardTo` delegate of protocol proxy.
        public var delegate: ProtocolProxy {
            return protocolProxy(for: UITableViewDelegate.self, keyPath: \.delegate)
        }

        /// A `ProtocolProxy` for the table view data source.
        ///
        /// - Note: Accessing this property for the first time will replace table view's current data source
        /// with a protocol proxy object (an object that is stored in this property).
        /// Current data source will be used as `forwardTo` data source of protocol proxy.
        public var dataSource: ProtocolProxy {
            return protocolProxy(for: UITableViewDataSource.self, keyPath: \.dataSource)
        }

        /// A signal that emits index paths of selected table view cells.
        ///
        /// - Note: Uses table view's `delegate` protocol proxy to observe calls made to `UITableViewDelegate.tableView(_:didSelectRowAt:)` method.
        public var selectedRowIndexPath: SafeSignal<IndexPath> {
            return delegate.signal(for: #selector(UITableViewDelegate.tableView(_:didSelectRowAt:))) { (subject: SafePublishSubject<IndexPath>, _: UITableView, indexPath: IndexPath) in
                subject.next(indexPath)
            }
        }
    }

    /// A type used by the table view bindings that provides binding options and actions.
    /// Subclass `TableViewBinder` to configure peculiarities of the bindings like animations.
    open class TableViewBinder<DataSource: DataSourceProtocol> {

        open var rowAnimation: UITableViewRowAnimation = .automatic

        open let createCell: (DataSource, IndexPath, UITableView) -> UITableViewCell

        /// - parameter createCell: A closure that creates cell for a given table view and configures it with the given data source at the given index path.
        public init(_ createCell: @escaping (DataSource, IndexPath, UITableView) -> UITableViewCell) {
            self.createCell = createCell
        }

        /// - returns: A cell for the given table view configured with the given data source at the given index path.
        open func cellForRow(at indexPath: IndexPath, tableView: UITableView, dataSource: DataSource) -> UITableViewCell {
            return createCell(dataSource, indexPath, tableView)
        }

        /// Applies the given data source event to the table view.
        ///
        /// For example, for `.insertItems(let indexPaths)` event the default implementation calls `tableView.insertRows(at: indexPaths, with: rowAnimation)`.
        ///
        /// Override to implement custom event application.
        open func apply(event: DataSourceEvent<DataSource, BatchKindDiff>, to tableView: UITableView) {
            switch event.kind {
            case .reload:
                tableView.reloadData()
            case .insertItems(let indexPaths):
                tableView.insertRows(at: indexPaths, with: rowAnimation)
            case .deleteItems(let indexPaths):
                tableView.deleteRows(at: indexPaths, with: rowAnimation)
            case .reloadItems(let indexPaths):
                tableView.reloadRows(at: indexPaths, with: rowAnimation)
            case .moveItem(let indexPath, let newIndexPath):
                tableView.moveRow(at: indexPath, to: newIndexPath)
            case .insertSections(let indexSet):
                tableView.insertSections(indexSet, with: rowAnimation)
            case .deleteSections(let indexSet):
                tableView.deleteSections(indexSet, with: rowAnimation)
            case .reloadSections(let indexSet):
                tableView.reloadSections(indexSet, with: rowAnimation)
            case .moveSection(let index, let newIndex):
                tableView.moveSection(index, toSection: newIndex)
            case .beginUpdates:
                tableView.beginUpdates()
            case .endUpdates:
                tableView.endUpdates()
            }
        }
    }

    /// A `TableViewBinder` subclass that applies events without animations or batching.
    /// Overrides `apply(event:)` method and just calls `tableView.reloadData()` for any event.
    open class ReloadingTableViewBinder<DataSource: DataSourceProtocol>: TableViewBinder<DataSource> {

        open override func apply(event: DataSourceEvent<DataSource, BatchKindDiff>, to tableView: UITableView) {
            tableView.reloadData()
        }
    }

    public extension SignalProtocol where Element: DataSourceEventProtocol, Element.BatchKind == BatchKindDiff, Error == NoError {

        public typealias DataSource = Element.DataSource

        /// Binds the signal of data source elements to the given table view.
        ///
        /// - parameters:
        ///     - tableView: A table view that should display the data from the data source.
        ///     - animated: Animate partial or batched updates. Default is `true`.
        ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `.automatic`.
        ///     - createCell: A closure that creates (dequeues) cell for the given table view and configures it with the given data source at the given index path.
        /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
        @discardableResult
        public func bind(to tableView: UITableView, animated: Bool = true, rowAnimation: UITableViewRowAnimation = .automatic, createCell: @escaping (DataSource, IndexPath, UITableView) -> UITableViewCell) -> Disposable {
            if animated {
                let binder = TableViewBinder<DataSource>(createCell)
                binder.rowAnimation = rowAnimation
                return bind(to: tableView, using: binder)
            } else {
                let binder = ReloadingTableViewBinder<DataSource>(createCell)
                binder.rowAnimation = rowAnimation
                return bind(to: tableView, using: binder)
            }
        }

        /// Binds the signal of data source elements to the given table view.
        ///
        /// - parameters:
        ///     - tableView: A table view that should display the data from the data source.
        ///     - binder: A `TableViewBinder` or its subclass that will manage the binding.
        /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
        @discardableResult
        public func bind(to tableView: UITableView, using binder: TableViewBinder<DataSource>) -> Disposable {
            let dataSource = Property<DataSource?>(nil)
            let disposable = CompositeDisposable()

            disposable += tableView.reactive.dataSource.feed(
                property: dataSource,
                to: #selector(UITableViewDataSource.tableView(_:cellForRowAt:)),
                map: { (dataSource: DataSource?, tableView: UITableView, indexPath: NSIndexPath) -> UITableViewCell in
                    return binder.cellForRow(at: indexPath as IndexPath, tableView: tableView, dataSource: dataSource!)
                }
            )

            // TODO: Remove when TableViewBond is removed
            if let bondBinder = binder as? AnyTableViewBondBinder<DataSource> {
                disposable += tableView.reactive.dataSource.feed(
                    property: dataSource,
                    to: #selector(UITableViewDataSource.tableView(_:titleForHeaderInSection:)),
                    map: { (dataSource: DataSource?, tableView: UITableView, index: Int) -> NSString? in
                        guard let dataSource = dataSource else { return nil }
                        return bondBinder.titleForHeader(in: index, dataSource: dataSource) as NSString?
                    }
                )

                disposable += tableView.reactive.dataSource.feed(
                    property: dataSource,
                    to: #selector(UITableViewDataSource.tableView(_:titleForFooterInSection:)),
                    map: { (dataSource: DataSource?, tableView: UITableView, index: Int) -> NSString? in
                        guard let dataSource = dataSource else { return nil }
                        return bondBinder.titleForFooter(in: index, dataSource: dataSource) as NSString?
                    }
                )
            }

            disposable += tableView.reactive.dataSource.feed(
                property: dataSource,
                to: #selector(UITableViewDataSource.tableView(_:numberOfRowsInSection:)),
                map: { (dataSource: DataSource?, _: UITableView, section: Int) -> Int in
                    dataSource?.numberOfItems(inSection: section) ?? 0
                }
            )

            disposable += tableView.reactive.dataSource.feed(
                property: dataSource,
                to: #selector(UITableViewDataSource.numberOfSections(in:)),
                map: { (dataSource: DataSource?, _: UITableView) -> Int in
                    dataSource?.numberOfSections ?? 0
                }
            )

            disposable += bind(to: tableView) { (tableView, event) in
                let event = event._unbox
                dataSource.value = event.dataSource
                binder.apply(event: event, to: tableView)
            }

            return disposable
        }
    }

    public extension SignalProtocol where Element: DataSourceEventProtocol, Element.DataSource: QueryableDataSourceProtocol, Element.DataSource.Index == IndexPath, Element.BatchKind == BatchKindDiff, Error == NoError {

        /// Binds the signal of data source elements to the given table view.
        ///
        /// - parameters:
        ///     - tableView: A table view that should display the data from the data source.
        ///     - cellType: A type of the cells that should display the data. Cell type name will be used as reusable identifier and the binding will automatically dequeue cell.
        ///     - animated: Animate partial or batched updates. Default is `true`.
        ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `.automatic`.
        ///     - configureCell: A closure that configures the cell with the data source item at the respective index path.
        /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
        @discardableResult
        public func bind<Cell: UITableViewCell>(to tableView: UITableView, cellType: Cell.Type, animated: Bool = true, rowAnimation: UITableViewRowAnimation = .automatic, configureCell: @escaping (Cell, DataSource.Item) -> Void) -> Disposable {
            let identifier = String(describing: Cell.self)
            tableView.register(cellType as AnyClass, forCellReuseIdentifier: identifier)
            return bind(to: tableView, animated: animated, rowAnimation: rowAnimation, createCell: { (dataSource, indexPath, tableView) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! Cell
                let item = dataSource.item(at: indexPath)
                configureCell(cell, item)
                return cell
            })
        }
    }

    public extension SignalProtocol where Element: DataSourceEventProtocol, Element.DataSource: QueryableDataSourceProtocol, Element.DataSource.Index == Int, Element.BatchKind == BatchKindDiff, Error == NoError {

        /// Binds the signal of data source elements to the given table view.
        ///
        /// - parameters:
        ///     - tableView: A table view that should display the data from the data source.
        ///     - cellType: A type of the cells that should display the data. Cell type name will be used as reusable identifier and the binding will automatically dequeue cell.
        ///     - animated: Animate partial or batched updates. Default is `true`.
        ///     - rowAnimation: Row animation for partial or batched updates. Relevant only when `animated` is `true`. Default is `.automatic`.
        ///     - configureCell: A closure that configures the cell with the data source item at the respective index path row.
        /// - returns: A disposable object that can terminate the binding. Safe to ignore - the binding will be automatically terminated when the table view is deallocated.
        @discardableResult
        public func bind<Cell: UITableViewCell>(to tableView: UITableView, cellType: Cell.Type, animated: Bool = true, rowAnimation: UITableViewRowAnimation = .automatic, configureCell: @escaping (Cell, DataSource.Item) -> Void) -> Disposable {
            let identifier = String(describing: Cell.self)
            tableView.register(cellType as AnyClass, forCellReuseIdentifier: identifier)
            return bind(to: tableView, animated: animated, rowAnimation: rowAnimation, createCell: { (dataSource, indexPath, tableView) -> UITableViewCell in
                let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! Cell
                let item = dataSource.item(at: indexPath.row)
                configureCell(cell, item)
                return cell
            })
        }
    }

    // MARK: Deprecated stuff

    @available(*, deprecated, message: "Subclass TableViewBinder instead.")
    public protocol TableViewBond {

        associatedtype DataSource: DataSourceProtocol

        func apply(event: DataSourceEvent<DataSource, BatchKindDiff>, to tableView: UITableView)
        func cellForRow(at indexPath: IndexPath, tableView: UITableView, dataSource: DataSource) -> UITableViewCell
        func titleForHeader(in section: Int, dataSource: DataSource) -> String?
        func titleForFooter(in section: Int, dataSource: DataSource) -> String?
    }

    @available(*, deprecated)
    extension TableViewBond {

        public func apply(event: DataSourceEvent<DataSource, BatchKindDiff>, to tableView: UITableView) {
            switch event.kind {
            case .reload:
                tableView.reloadData()
            case .insertItems(let indexPaths):
                tableView.insertRows(at: indexPaths, with: .automatic)
            case .deleteItems(let indexPaths):
                tableView.deleteRows(at: indexPaths, with: .automatic)
            case .reloadItems(let indexPaths):
                tableView.reloadRows(at: indexPaths, with: .automatic)
            case .moveItem(let indexPath, let newIndexPath):
                tableView.moveRow(at: indexPath, to: newIndexPath)
            case .insertSections(let indexSet):
                tableView.insertSections(indexSet, with: .automatic)
            case .deleteSections(let indexSet):
                tableView.deleteSections(indexSet, with: .automatic)
            case .reloadSections(let indexSet):
                tableView.reloadSections(indexSet, with: .automatic)
            case .moveSection(let index, let newIndex):
                tableView.moveSection(index, toSection: newIndex)
            case .beginUpdates:
                tableView.beginUpdates()
            case .endUpdates:
                tableView.endUpdates()
            }
        }

        public func titleForHeader(in section: Int, dataSource: DataSource) -> String? {
            return nil
        }

        public func titleForFooter(in section: Int, dataSource: DataSource) -> String? {
            return nil
        }
    }

    @available(*, deprecated)
    private struct DefaultTableViewBond<DataSource: DataSourceProtocol>: TableViewBond {

        let createCell: (DataSource, IndexPath, UITableView) -> UITableViewCell

        func cellForRow(at indexPath: IndexPath, tableView: UITableView, dataSource: DataSource) -> UITableViewCell {
            return createCell(dataSource, indexPath, tableView)
        }
    }

    @available(*, deprecated)
    private struct ReloadingTableViewBond<DataSource: DataSourceProtocol>: TableViewBond {

        let createCell: (DataSource, IndexPath, UITableView) -> UITableViewCell

        func cellForRow(at indexPath: IndexPath, tableView: UITableView, dataSource: DataSource) -> UITableViewCell {
            return createCell(dataSource, indexPath, tableView)
        }

        func apply(event: DataSourceEvent<DataSource, BatchKindDiff>, to tableView: UITableView) {
            tableView.reloadData()
        }
    }

    private class AnyTableViewBondBinder<DataSource: DataSourceProtocol>: TableViewBinder<DataSource> {

        func titleForHeader(in section: Int, dataSource: DataSource) -> String? {
            return nil
        }

        func titleForFooter(in section: Int, dataSource: DataSource) -> String? {
            return nil
        }
    }

    @available(*, deprecated)
    private class TableViewBondBinder<Bond: TableViewBond>: AnyTableViewBondBinder<Bond.DataSource> {

        let bond: Bond

        init(_ bond: Bond) {
            self.bond = bond

            super.init { (dataSource, indexPath, tableView) -> UITableViewCell in
                return bond.cellForRow(at: indexPath, tableView: tableView, dataSource: dataSource)
            }
        }

        override func apply(event: DataSourceEvent<Bond.DataSource, BatchKindDiff>, to tableView: UITableView) {
            bond.apply(event: event, to: tableView)
        }

        override func titleForHeader(in section: Int, dataSource: Bond.DataSource) -> String? {
            return bond.titleForHeader(in: section, dataSource: dataSource)
        }

        override func titleForFooter(in section: Int, dataSource: Bond.DataSource) -> String? {
            return bond.titleForFooter(in: section, dataSource: dataSource)
        }
    }

    public extension SignalProtocol where Element: DataSourceEventProtocol, Element.BatchKind == BatchKindDiff, Error == NoError {

        @available(*, deprecated, message: "Use an overload that accepts TableViewBinder object instead of deprecated TableViewBond.")
        @discardableResult
        public func bind<B: TableViewBond>(to tableView: UITableView, using bond: B) -> Disposable where B.DataSource == DataSource {
            return bind(to: tableView, using: TableViewBondBinder(bond))
        }
    }

#endif
