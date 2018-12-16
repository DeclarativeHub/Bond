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

#if os(iOS)

import UIKit
import ReactiveKit

public extension ReactiveExtensions where Base: UIPickerView {

    /// A `ProtocolProxy` for the picker view data source.
    ///
    /// - Note: Accessing this property for the first time will replace picker view's current data source
    /// with a protocol proxy object (an object that is stored in this property).
    /// Current data source will be used as `forwardTo` data source of protocol proxy.
    public var dataSource: ProtocolProxy {
        return protocolProxy(for: UIPickerViewDataSource.self, keyPath: \.dataSource)
    }

    /// A `ProtocolProxy` for the picker view delegate.
    ///
    /// - Note: Accessing this property for the first time will replace table view's current delegate
    /// with a protocol proxy object (an object that is stored in this property).
    /// Current delegate will be used as `forwardTo` delegate of protocol proxy.
    public var delegate: ProtocolProxy {
        return protocolProxy(for: UIPickerViewDelegate.self, keyPath: \.delegate)
    }

    /// A signal that emits the row and component index of the selected picker view row.
    ///
    /// - Note: Uses picker view's `delegate` protocol proxy to observe calls made to `UIPickerViewDelegate.pickerView(_:didSelectRow:inComponent:)` method.
    public var selectedRow: SafeSignal<(Int, Int)> {
        return delegate.signal(
            for: #selector(UIPickerViewDelegate.pickerView(_:didSelectRow:inComponent:)),
            dispatch: { (
                subject: SafePublishSubject<(Int, Int)>,
                pickerView: UIPickerView,
                row: Int,
                component: Int) -> Void in
                subject.next((row, component))
            }
        )
    }
}

#endif
