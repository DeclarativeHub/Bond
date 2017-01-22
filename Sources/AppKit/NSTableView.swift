//
//  NSTableView.swift
//  Bond
//
//  Created by Srdan Rasic on 18/08/16.
//  Copyright © 2016 Swift Bond. All rights reserved.
//

import AppKit
import ReactiveKit

public protocol TableViewConfigurationProtocol {
	var animated: Bool { get }
	var insertAnimation: NSTableViewAnimationOptions { get }
	var deleteAnimation: NSTableViewAnimationOptions { get }
	var measureCell: ((Any, Int, NSTableView) -> CGFloat)? { get }
	var createCell: (Any, Int, NSTableView) -> NSView? { get }
}

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

private final class DefaultTableViewConfiguration: TableViewConfigurationProtocol {
	init(animated: Bool, createCell: @escaping (Any, Int, NSTableView) -> NSView?) {
		self.animated = animated
		self.createCell = createCell
	}
	
	let animated: Bool
	let insertAnimation: NSTableViewAnimationOptions = []
	let deleteAnimation: NSTableViewAnimationOptions = []
	let measureCell: ((Any, Int, NSTableView) -> CGFloat)? = nil
	let createCell: (Any, Int, NSTableView) -> NSView?
}

public extension SignalProtocol where Element: DataSourceEventProtocol, Element.DataSource: QueryableDataSourceProtocol, Element.DataSource.Item: Any, Element.DataSource.Index == Int, Error == NoError {

  public typealias DataSource = Element.DataSource
	
	@discardableResult
	public func bind(to tableView: NSTableView, animated: Bool = true, createCell: @escaping (DataSource, Int, NSTableView) -> NSView?) -> Disposable {
		let configurator = DefaultTableViewConfiguration(animated: animated) { (source, index, tableView) -> NSView? in
			return createCell(source as! DataSource, index, tableView)
		}
		return bind(to: tableView, configurator: configurator)
	}
	
  @discardableResult
	public func bind(to tableView: NSTableView, configurator: TableViewConfigurationProtocol) -> Disposable {
		
    let dataSource = Property<DataSource?>(nil)

		if let measureCell = configurator.measureCell {
      tableView.reactive.delegate.feed(
				property: dataSource,
				to: #selector(NSTableViewDelegate.tableView(_:heightOfRow:)),
				map: { (dataSource: DataSource?, tableView: NSTableView, row: Int) -> CGFloat in measureCell(dataSource!, row, tableView) }
      )
		}
		
    tableView.reactive.delegate.feed(
      property: dataSource,
      to: #selector(NSTableViewDelegate.tableView(_:viewFor:row:)),
      map: { (dataSource: DataSource?, tableView: NSTableView, _: NSTableColumn, row: Int) -> NSView? in
        return configurator.createCell(dataSource!, row, tableView)
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
    var updating = false

    serialDisposable.otherDisposable = observeIn(ImmediateOnMainExecutionContext).observeNext { [weak tableView] event in
      guard let tableView = tableView else {
        serialDisposable.dispose()
        return
      }

      dataSource.value = event.dataSource

      guard configurator.animated else {
        tableView.reloadData()
        return
      }

      switch event.kind {
      case .reload:
        tableView.reloadData()
      case .insertItems(let indexPaths):
        if !updating && indexPaths.count > 1 {
          tableView.beginUpdates()
          defer { tableView.endUpdates() }
        }
        indexPaths.forEach { indexPath in
          tableView.insertRows(at: IndexSet(integer: indexPath.item), withAnimation: configurator.insertAnimation)
        }
      case .deleteItems(let indexPaths):
        if !updating && indexPaths.count > 1 {
          tableView.beginUpdates()
          defer { tableView.endUpdates() }
        }
        indexPaths.forEach { indexPath in
          tableView.removeRows(at: IndexSet(integer: indexPath.item), withAnimation: configurator.deleteAnimation)
        }
      case .reloadItems(let indexPaths):
        if !updating && indexPaths.count > 1 {
          tableView.beginUpdates()
          defer { tableView.endUpdates() }
        }
        indexPaths.forEach { indexPath in
          tableView.removeRows(at: IndexSet(integer: indexPath.item), withAnimation: configurator.deleteAnimation)
          tableView.insertRows(at: IndexSet(integer: indexPath.item), withAnimation: configurator.insertAnimation)
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
        updating = true
      case .endUpdates:
        updating = false
        tableView.endUpdates()
      }
    }
    
    return serialDisposable
  }
}
