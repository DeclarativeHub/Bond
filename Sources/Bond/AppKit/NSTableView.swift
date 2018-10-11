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

    /// A `ProtocolProxy` for the table view delegate.
    ///
    /// - Note: Accessing this property for the first time will replace table view's current delegate
    /// with a protocol proxy object (an object that is stored in this property).
    /// Current delegate will be used as `forwardTo` delegate of protocol proxy.
    public var delegate: ProtocolProxy {
        return protocolProxy(for: NSTableViewDelegate.self, keyPath: \.delegate)
    }

    /// A `ProtocolProxy` for the table view data source.
    ///
    /// - Note: Accessing this property for the first time will replace table view's current data source
    /// with a protocol proxy object (an object that is stored in this property).
    /// Current data source will be used as `forwardTo` data source of protocol proxy.
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

#endif
