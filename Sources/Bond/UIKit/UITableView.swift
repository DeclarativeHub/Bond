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

extension ReactiveExtensions where Base: UITableView {

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
        return delegate.signal(for: #selector(UITableViewDelegate.tableView(_:didSelectRowAt:))) { (subject: PassthroughSubject<IndexPath, Never>, _: UITableView, indexPath: IndexPath) in
            subject.send(indexPath)
        }
    }
}

#endif
