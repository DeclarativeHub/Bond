//
//  NSTableView.swift
//  Bond
//
//  Created by Srdan Rasic on 18/08/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import ObjectiveC
import AppKit
import ReactiveKit

public extension ReactiveExtensions where Base: NSTableView {

  public var delegate: ProtocolProxy {
    return base.protocolProxy(for: NSTableViewDelegate.self, setter: NSSelectorFromString("setDelegate:"))
  }

  public var dataSource: ProtocolProxy {
    return base.protocolProxy(for: NSTableViewDataSource.self, setter: NSSelectorFromString("setDataSource:"))
  }

  public var selectionIsChanging: SafeSignal<Void> {
    return NotificationCenter.default.reactive.notification(name: .NSTableViewSelectionIsChanging, object: base).eraseType()
  }

  public var selectionDidChange: SafeSignal<Void> {
    return NotificationCenter.default.reactive.notification(name: .NSTableViewSelectionDidChange, object: base).eraseType()
  }

  public var selectedRowIndexes: Bond<IndexSet> {
    return bond { $0.selectRowIndexes($1, byExtendingSelection: false) }
  }

  public var selectedColumnIndexes: Bond<IndexSet> {
    return bond { $0.selectColumnIndexes($1, byExtendingSelection: false) }
  }
}

// MARK: - Table view integration

extension NSTableView {
	
	fileprivate var updating: Bool {
		get {
			return objc_getAssociatedObject(self, &NSTableViewUpdatingKey) as? Bool ?? false
		}
		set {
			objc_setAssociatedObject(self, &NSTableViewUpdatingKey, newValue, .OBJC_ASSOCIATION_RETAIN)
		}
	}
}

private var NSTableViewUpdatingKey: UInt8 = 0

// MARK: - Bond declaration

public protocol TableViewBondOptionable {
	var insertAnimation: NSTableViewAnimationOptions? { get }
	var deleteAnimation: NSTableViewAnimationOptions? { get }
}

public protocol TableViewBond: TableViewBondOptionable {
	
	associatedtype DataSource: DataSourceProtocol
	
	func apply(event: DataSourceEvent<DataSource>, to tableView: NSTableView)
	func heightForRow(at index: Int, tableView: NSTableView, dataSource: DataSource) -> CGFloat?
	func cellForRow(at index: Int, tableView: NSTableView, dataSource: DataSource) -> NSView?
}

extension TableViewBond {
	
	public var insertAnimation: NSTableViewAnimationOptions? {
		return nil
	}
	
	public var deleteAnimation: NSTableViewAnimationOptions? {
		return nil
	}
	
	public func heightForRow(at index: Int, tableView: NSTableView, dataSource: DataSource) -> CGFloat? {
		return nil
	}
	
	public func apply(event: DataSourceEvent<DataSource>, to tableView: NSTableView) {
		if insertAnimation == nil && deleteAnimation == nil {
			tableView.reloadData()
			return
		}
		
		switch event.kind {
		case .reload:
			tableView.reloadData()
		case .insertItems(let indexPaths):
			if !tableView.updating && indexPaths.count > 1 {
				tableView.beginUpdates()
				defer { tableView.endUpdates() }
			}
			indexPaths.forEach { indexPath in
				tableView.insertRows(at: IndexSet(integer: indexPath.item), withAnimation: insertAnimation ?? [])
			}
		case .deleteItems(let indexPaths):
			if !tableView.updating && indexPaths.count > 1 {
				tableView.beginUpdates()
				defer { tableView.endUpdates() }
			}
			indexPaths.forEach { indexPath in
				tableView.removeRows(at: IndexSet(integer: indexPath.item), withAnimation: deleteAnimation ?? [])
			}
		case .reloadItems(let indexPaths):
			if !tableView.updating && indexPaths.count > 1 {
				tableView.beginUpdates()
				defer { tableView.endUpdates() }
			}
			indexPaths.forEach { indexPath in
				tableView.removeRows(at: IndexSet(integer: indexPath.item), withAnimation: deleteAnimation ?? [])
				tableView.insertRows(at: IndexSet(integer: indexPath.item), withAnimation: insertAnimation ?? [])
			}
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
			tableView.updating = true
		case .endUpdates:
			tableView.updating = false
			tableView.endUpdates()
		}
	}
}

// MARK: - Builtin bonds

private struct DefaultTableViewBond<DataSource: DataSourceProtocol>: TableViewBond {
	
	let createCell: (DataSource, Int, NSTableView) -> NSView?
	
	var animations: NSTableViewAnimationOptions
	
	var insertAnimation: NSTableViewAnimationOptions? {
		return animations
	}
	
	var deleteAnimation: NSTableViewAnimationOptions? {
		return animations
	}
	
	func cellForRow(at index: Int, tableView: NSTableView, dataSource: DataSource) -> NSView? {
		return createCell(dataSource, index, tableView)
	}
}

private struct ReloadingTableViewBond<DataSource: DataSourceProtocol>: TableViewBond {
	
	let createCell: (DataSource, Int, NSTableView) -> NSView?
	
	func cellForRow(at index: Int, tableView: NSTableView, dataSource: DataSource) -> NSView? {
		return createCell(dataSource, index, tableView)
	}
	
	func apply(event: DataSourceEvent<DataSource>, to tableView: NSTableView) {
		tableView.reloadData()
	}
}

// MARK: - Bond implementation

public extension SignalProtocol where Element: DataSourceEventProtocol, Element.DataSource: QueryableDataSourceProtocol, Element.DataSource.Item: Any, Element.DataSource.Index == Int, Error == NoError {

  public typealias DataSource = Element.DataSource
	
	@discardableResult
	public func bind(to tableView: NSTableView, animated: Bool = true, createCell: @escaping (DataSource, Int, NSTableView) -> NSView?) -> Disposable {
		if animated {
			return bind(to: tableView, using: DefaultTableViewBond<DataSource>(createCell: createCell, animations: [.effectFade, .slideUp]))
		} else {
			return bind(to: tableView, using: ReloadingTableViewBond<DataSource>(createCell: createCell))
		}
	}
	
	@discardableResult
	public func bind<B: TableViewBond>(to tableView: NSTableView, using bond: B) -> Disposable where B.DataSource == DataSource {
	
    let dataSource = Property<DataSource?>(nil)

		tableView.reactive.delegate.feed(
			property: dataSource,
			to: #selector(NSTableViewDelegate.tableView(_:heightOfRow:)),
			map: { (dataSource: DataSource?, tableView: NSTableView, row: Int) -> CGFloat in
				guard let dataSource = dataSource else { return tableView.rowHeight }
				return bond.heightForRow(at: row, tableView: tableView, dataSource: dataSource) ?? tableView.rowHeight
		})
	
    tableView.reactive.delegate.feed(
      property: dataSource,
      to: #selector(NSTableViewDelegate.tableView(_:viewFor:row:)),
      map: { (dataSource: DataSource?, tableView: NSTableView, _: NSTableColumn, row: Int) -> NSView? in
				guard let dataSource = dataSource else { return nil }
        return bond.cellForRow(at: row, tableView: tableView, dataSource: dataSource)
      }
    )

    tableView.reactive.dataSource.feed(
      property: dataSource,
      to: #selector(NSTableViewDataSource.numberOfRows(in:)),
      map: { (dataSource: DataSource?, _: NSTableView) -> Int in
        return dataSource?.numberOfItems(inSection: 0) ?? 0
      }
    )

    tableView.reactive.dataSource.feed(
      property: dataSource,
      to: #selector(NSTableViewDataSource.tableView(_:objectValueFor:row:)),
      map: { (dataSource: DataSource?, _: NSTableView, _: NSTableColumn, row: Int) -> Any? in
        return dataSource?.item(at: row)
      }
    )

    let serialDisposable = SerialDisposable(otherDisposable: nil)

    serialDisposable.otherDisposable = observeIn(ImmediateOnMainExecutionContext).observeNext { [weak tableView] event in
      guard let tableView = tableView else {
        serialDisposable.dispose()
        return
      }

			let event = event._unbox
      dataSource.value = event.dataSource
			bond.apply(event: event, to: tableView)
		}
		
    return serialDisposable
  }
}
